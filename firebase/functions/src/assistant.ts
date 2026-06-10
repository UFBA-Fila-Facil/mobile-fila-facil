import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Inicializa apenas se necessário (evita erro em hot-reload)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Endpoint para o Google Assistant / Dialogflow webhook.
 * Aceita POST com parâmetros nos formatos:
 * - req.body.queryResult.parameters (Dialogflow)
 * - req.body.parameters (generic)
 * - req.body (direct payload)
 * Parâmetros esperados: establishmentId | cep | establishmentName, quantityPeople, averageWaitTime
 */
export const assistantUpdateQueue = functions
  .region('us-central1')
  .https.onRequest(async (req, res) => {
    try {
      if (req.method !== 'POST') {
        res.status(405).send('Method Not Allowed');
        return;
      }

      // Extract parameters flexibly
      const body = req.body || {};
      const params =
        (body.queryResult && body.queryResult.parameters) || body.parameters || body;

      const establishmentId = params.establishmentId || params.establishment_id || params.establishment || null;
      const cep = params.cep || params.CEP || null;
      const establishmentName = params.establishmentName || params.name || null;

      let quantityPeople = params.quantityPeople ?? params.quantity_people ?? params.people ?? null;
      let averageWaitTime = params.averageWaitTime ?? params.average_wait_time ?? params.waitTime ?? null;

      // Try parse numbers
      if (typeof quantityPeople === 'string') quantityPeople = parseInt(quantityPeople, 10);
      if (typeof averageWaitTime === 'string') averageWaitTime = parseInt(averageWaitTime, 10);

      if (!establishmentId && !cep && !establishmentName) {
        const msg = 'Parâmetro ausente: informe establishmentId, cep ou establishmentName';
        res.status(400).json({ error: msg, fulfillmentText: msg });
        return;
      }

      if (quantityPeople == null && averageWaitTime == null) {
        const msg = 'Parâmetro ausente: informe quantityPeople e/ou averageWaitTime';
        res.status(400).json({ error: msg, fulfillmentText: msg });
        return;
      }

      // Resolve establishmentId by cep or name if necessary
      let estId = establishmentId;

      if (!estId) {
        let query = db.collection('establishments').limit(1) as FirebaseFirestore.Query;
        if (cep) query = query.where('cep', '==', cep);
        else if (establishmentName) query = query.where('name', '==', establishmentName);

        const snap = await query.get();
        if (snap.empty) {
          const msg = 'Estabelecimento não encontrado para os parâmetros fornecidos.';
          res.status(404).json({ error: msg, fulfillmentText: msg });
          return;
        }

        estId = snap.docs[0].id;
      }

      const queueRef = db.collection('queues').doc(estId);

      const updateData: any = { updatedAt: admin.firestore.Timestamp.now() };
      if (typeof quantityPeople === 'number' && !Number.isNaN(quantityPeople)) {
        updateData.quantityPeople = quantityPeople;
      }
      if (typeof averageWaitTime === 'number' && !Number.isNaN(averageWaitTime)) {
        updateData.averageWaitTime = averageWaitTime;
      }

      await queueRef.set(updateData, { merge: true });

      const successText = `Fila atualizada para o estabelecimento ${estId}: ${updateData.quantityPeople ?? '—'} pessoas, tempo médio ${updateData.averageWaitTime ?? '—'} minutos.`;

      // Dialogflow expects a fulfillmentText field
      res.status(200).json({ success: true, fulfillmentText: successText });
    } catch (error) {
      console.error('assistantUpdateQueue error', error);
      const msg = error instanceof Error ? error.message : 'Unknown error';
      res.status(500).json({ success: false, error: msg, fulfillmentText: `Erro: ${msg}` });
    }
  });
