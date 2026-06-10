import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Inicializar Firebase Admin
admin.initializeApp();

const db = admin.firestore();

// Constantes
const RADIUS_METERS = 20;
const EARTH_RADIUS_METERS = 6371000;

/**
 * Calcula a distância entre dois pontos geográficos usando a fórmula de Haversine
 * @param lat1 Latitude do primeiro ponto
 * @param lon1 Longitude do primeiro ponto
 * @param lat2 Latitude do segundo ponto
 * @param lon2 Longitude do segundo ponto
 * @returns Distância em metros
 */
function calculateDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return EARTH_RADIUS_METERS * c;
}

/**
 * Converte graus para radianos
 */
function toRad(deg: number): number {
  return deg * (Math.PI / 180);
}

/**
 * Cloud Function acionada por Cloud Scheduler a cada 10 minutos
 * Atualiza a quantidade de usuários próximos a cada estabelecimento
 */
export const updateQueueUsers = functions
  .region('us-central1')
  .https.onRequest(async (req, res) => {
    try {
      console.log('Iniciando atualização de filas...');

      // Obter todos os estabelecimentos
      const establishmentsSnapshot = await db.collection('establishments').get();

      if (establishmentsSnapshot.empty) {
        console.log('Nenhum estabelecimento encontrado.');
        res.status(200).json({ message: 'No establishments found' });
        return;
      }

      let processedCount = 0;
      let errorCount = 0;

      // Para cada estabelecimento
      for (const estDoc of establishmentsSnapshot.docs) {
        try {
          const establishment = estDoc.data();
          const estId = estDoc.id;

          // Validar se tem localização
          if (!establishment.location || !establishment.location._latitude || !establishment.location._longitude) {
            console.warn(`Estabelecimento ${estId} sem localização válida.`);
            continue;
          }

          const estLat = establishment.location._latitude;
          const estLon = establishment.location._longitude;

          // Buscar usuários próximos (filtro inicial - bounding box)
          const usersSnapshot = await db.collection('users').get();

          const nearbyUsers: Array<{
            userId: string;
            distance: number;
          }> = [];

          // Calcular distância para cada usuário
          for (const userDoc of usersSnapshot.docs) {
            const user = userDoc.data();
            const userId = userDoc.id;

            // Validar se tem localização
            if (!user.location || !user.location._latitude || !user.location._longitude) {
              continue;
            }

            const userLat = user.location._latitude;
            const userLon = user.location._longitude;

            // Calcular distância
            const distance = calculateDistance(estLat, estLon, userLat, userLon);

            // Se está dentro do raio
            if (distance <= RADIUS_METERS) {
              nearbyUsers.push({
                userId: userId,
                distance: distance,
              });
            }
          }

          console.log(
            `Estabelecimento ${establishment.name}: ${nearbyUsers.length} usuários próximos`
          );

          // Atualizar ou criar fila
          const queueRef = db.collection('queues').doc(estId);
          const existingQueue = await queueRef.get();

          // Remover usuários antigos da fila
          const oldUsersSnapshot = await db
            .collection('usersInQueue')
            .where('queueId', '==', estId)
            .get();

          const batch = db.batch();

          // Remover referências antigas
          for (const oldUserDoc of oldUsersSnapshot.docs) {
            batch.delete(oldUserDoc.ref);
          }

          // Atualizar fila com novo número de pessoas
          const queueData = {
            establishmentId: estId,
            establishmentName: establishment.name,
            quantityPeople: nearbyUsers.length,
            averageWaitTime: calculateAverageWaitTime(nearbyUsers.length, establishment.capacity),
            serviceType: establishment.serviceType || 'Padrão',
            updatedAt: admin.firestore.Timestamp.now(),
          };

          batch.set(queueRef, queueData, { merge: true });

          // Adicionar novos usuários na fila
          for (const nearbyUser of nearbyUsers) {
            const userQueueRef = db
              .collection('usersInQueue')
              .doc(`${estId}_${nearbyUser.userId}`);

            batch.set(userQueueRef, {
              queueId: estId,
              userId: nearbyUser.userId,
              distanceMeters: nearbyUser.distance,
              addedAt: admin.firestore.Timestamp.now(),
              wasServed: false,
            });
          }

          // Executar batch
          await batch.commit();

          processedCount++;
        } catch (error) {
          console.error(`Erro ao processar estabelecimento: ${error}`);
          errorCount++;
        }
      }

      // Registrar resumo
      console.log(
        `Atualização concluída: ${processedCount} estabelecimentos processados, ${errorCount} erros`
      );

      res.status(200).json({
        success: true,
        processed: processedCount,
        errors: errorCount,
      });
    } catch (error) {
      console.error('Erro na function updateQueueUsers:', error);
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  });

/**
 * Calcula tempo médio de espera baseado na quantidade de pessoas e capacidade
 * Fórmula: (quantidade / capacidade) * 60 minutos
 */
function calculateAverageWaitTime(
  quantityPeople: number,
  capacity: number
): number {
  if (!capacity || capacity <= 0) return 0;
  const ratioLoad = quantityPeople / capacity;
  // Multiplica por 10 minutos como tempo base por pessoa
  return Math.ceil(ratioLoad * 10);
}

/**
 * Função auxiliar: Limpar usuários da fila que se afastaram
 * Pode ser chamada separadamente se necessário
 */
export const cleanupStaleQueueUsers = functions
  .region('us-central1')
  .https.onRequest(async (req, res) => {
    try {
      const cutoffTime = new Date(Date.now() - 30 * 60 * 1000); // 30 minutos atrás

      const snapshot = await db
        .collection('usersInQueue')
        .where('addedAt', '<', admin.firestore.Timestamp.fromDate(cutoffTime))
        .where('wasServed', '==', false)
        .get();

      const batch = db.batch();
      let deletedCount = 0;

      for (const doc of snapshot.docs) {
        batch.delete(doc.ref);
        deletedCount++;
      }

      await batch.commit();

      console.log(`Limpeza concluída: ${deletedCount} registros removidos`);
      res.status(200).json({ deleted: deletedCount });
    } catch (error) {
      console.error('Erro na limpeza:', error);
      res.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });
