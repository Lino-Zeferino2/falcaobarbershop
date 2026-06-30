const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
require('dotenv').config();

// Initialize Firebase Admin SDK with service account
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'falcaobarbershopv2',
  databaseId: '(default)'
});

// Configurar o transportador de email usando environment variables
const getTransporter = () => {
  return nodemailer.createTransport({
    service: 'gmail', // ou outro provedor
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS
    }
  });
};

// Templates de email
const emailTemplates = {
  'booking_received': {
    subject: 'Agendamento Recebido - Falcão Barbershop',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #B22222;">Olá {{name}},</h2>
        <p>Recebemos seu pedido de agendamento! Aqui estão os detalhes:</p>
        <div style="background-color: #f8f8f8; padding: 20px; border-radius: 10px; margin: 20px 0;">
          <p><strong>Serviço:</strong> {{service}}</p>
          <p><strong>Preço:</strong> {{price}}</p>
          <p><strong>Profissional:</strong> {{professional}}</p>
          <p><strong>Data:</strong> {{date}}</p>
          <p><strong>Hora:</strong> {{time}}</p>
          <p><strong>Barbearia:</strong> {{barbearia}}</p>
          <p><strong>Nome:</strong> {{name}}</p>
          <p><strong>Telefone:</strong> {{phone}}</p>
          <p><strong>Email:</strong> {{email}}</p>
        </div>
        <p>Seu agendamento está aguardando aprovação. Você receberá um email de confirmação assim que for aprovado.</p>
        <p>Se precisar cancelar ou alterar seu agendamento, acesse a página <a href="https://falcaobarbershopv2.web.app/history" style="color: #B22222; font-weight: bold;">Meus Agendamentos</a> onde você pode gerenciar seus compromissos.</p>
        <p>Visite nosso site: <a href="https://falcaobarbershopv2.web.app">falcaobarbershopv2.web.app</a></p>
        <p>Atenciosamente,<br><strong>Falcão Barbershop</strong></p>
      </div>
    `
  },
  'booking_confirmed': {
    subject: 'Agendamento Confirmado - Falcão Barbershop',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #B22222;">Olá {{name}},</h2>
        <p>Seu agendamento foi confirmado! Aqui estão os detalhes:</p>
        <div style="background-color: #f8f8f8; padding: 20px; border-radius: 10px; margin: 20px 0;">
          <p><strong>Serviço:</strong> {{service}}</p>
          <p><strong>Preço:</strong> {{price}}</p>
          <p><strong>Profissional:</strong> {{professional}}</p>
          <p><strong>Data:</strong> {{date}}</p>
          <p><strong>Hora:</strong> {{time}}</p>
          <p><strong>Barbearia:</strong> {{barbearia}}</p>
          <p><strong>Nome:</strong> {{name}}</p>
          <p><strong>Telefone:</strong> {{phone}}</p>
          <p><strong>Email:</strong> {{email}}</p>
        </div>
        <p><strong>Por favor, chegue 10 minutos antes do horário marcado.</strong></p>
        <p>Se precisar cancelar ou alterar seu agendamento, acesse a página <a href="https://falcaobarbershopv2.web.app/history" style="color: #B22222; font-weight: bold;">Meus Agendamentos</a> onde você pode gerenciar seus compromissos.</p>
        <p>Visite nosso site: <a href="https://falcaobarbershopv2.web.app">falcaobarbershopv2.web.app</a></p>
        <p>Atenciosamente,<br><strong>Falcão Barbershop</strong></p>
      </div>
    `
  },
  'booking_cancelled': {
    subject: 'Agendamento Cancelado - Falcão Barbershop',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #B22222;">Olá {{name}},</h2>
        <p>Seu agendamento foi cancelado. Aqui estão os detalhes:</p>
        <div style="background-color: #f8f8f8; padding: 20px; border-radius: 10px; margin: 20px 0;">
          <p><strong>Serviço:</strong> {{service}}</p>
          <p><strong>Preço:</strong> {{price}}</p>
          <p><strong>Profissional:</strong> {{professional}}</p>
          <p><strong>Data:</strong> {{date}}</p>
          <p><strong>Hora:</strong> {{time}}</p>
          <p><strong>Barbearia:</strong> {{barbearia}}</p>
        </div>
        <p>Se desejar reagendar, visite nosso aplicativo.</p>
        <p>Visite nosso site: <a href="https://falcaobarbershopv2.web.app">falcaobarbershopv2.web.app</a></p>
        <p>Atenciosamente,<br><strong>Falcão Barbershop</strong></p>
      </div>
    `
  },
  'review_request': {
    subject: 'Como foi seu atendimento? - Falcão Barbershop',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #B22222;">Olá {{name}},</h2>
        <p>Obrigado por escolher o Falcão Barbershop! Sua opinião é muito importante para nós.</p>
        <p>Como foi seu atendimento? Deixe sua avaliação no Google:</p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="{{review_url}}" style="background-color: #B22222; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; font-weight: bold;">
            Deixar Avaliação no Google
          </a>
        </div>
        <p>Ficaremos muito gratos se nos ajudar a crescer com sua avaliação!</p>
        <p>Sua avaliação nos ajuda a melhorar nossos serviços!</p>
        <p>Visite nosso site: <a href="https://falcaobarbershopv2.web.app">falcaobarbershopv2.web.app</a></p>
        <p>Atenciosamente,<br><strong>Falcão Barbershop</strong></p>
      </div>
    `
  },
  'admin_booking_notification': {
    subject: 'Novo Agendamento Recebido - Falcão Barbershop',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #B22222;">Novo Agendamento Recebido</h2>
        <p>Um novo agendamento foi criado no sistema. Aqui estão os detalhes:</p>
        <div style="background-color: #f8f8f8; padding: 20px; border-radius: 10px; margin: 20px 0;">
          <p><strong>Nome do Cliente:</strong> {{name}}</p>
          <p><strong>Serviço:</strong> {{service}}</p>
          <p><strong>Preço:</strong> {{price}}</p>
          <p><strong>Profissional:</strong> {{professional}}</p>
          <p><strong>Data:</strong> {{date}}</p>
          <p><strong>Hora:</strong> {{time}}</p>
          <p><strong>Barbearia:</strong> {{barbearia}}</p>
          <p><strong>Telefone:</strong> {{phone}}</p>
          <p><strong>Email:</strong> {{email}}</p>
        </div>
        <p>Por favor, verifique o sistema para confirmar ou gerenciar este agendamento.</p>
        <p>Visite nosso site: <a href="https://falcaobarbershopv2.web.app">falcaobarbershopv2.web.app</a></p>
        <p>Atenciosamente,<br><strong>Sistema Falcão Barbershop</strong></p>
      </div>
    `
  },
  'appointment_reminder': {
    subject: 'Lembrete: Seu agendamento está próximo - Falcão Barbershop',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #B22222;">Olá {{name}},</h2>
        <p>Este é um lembrete automático do seu agendamento que está próximo!</p>
        <div style="background-color: #f8f8f8; padding: 20px; border-radius: 10px; margin: 20px 0;">
          <p><strong>Serviço:</strong> {{service}}</p>
          <p><strong>Preço:</strong> {{price}}</p>
          <p><strong>Profissional:</strong> {{professional}}</p>
          <p><strong>Data:</strong> {{date}}</p>
          <p><strong>Hora:</strong> {{time}}</p>
          <p><strong>Barbearia:</strong> {{barbearia}}</p>
          <p><strong>Nome:</strong> {{name}}</p>
          <p><strong>Telefone:</strong> {{phone}}</p>
          <p><strong>Email:</strong> {{email}}</p>
        </div>
        <p><strong>Seu agendamento está marcado para daqui a 1h30min!</strong></p>
        <p>Por favor, chegue 10 minutos antes do horário marcado.</p>
        <p>Se precisar cancelar ou alterar, entre em contato conosco com antecedência mínima de 1h.</p>
        <p>Visite nosso site: <a href="https://falcaobarbershopv2.web.app">falcaobarbershopv2.web.app</a></p>
        <p>Atenciosamente,<br><strong>Falcão Barbershop</strong></p>
      </div>
    `
  },
  'appointment_reminder_1day': {
    subject: 'Lembrete: Seu agendamento é amanhã - Falcão Barbershop',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #B22222;">Olá {{name}},</h2>
        <p>Este é um lembrete automático do seu agendamento marcado para amanhã!</p>
        <div style="background-color: #f8f8f8; padding: 20px; border-radius: 10px; margin: 20px 0;">
          <p><strong>Serviço:</strong> {{service}}</p>
          <p><strong>Preço:</strong> {{price}}</p>
          <p><strong>Profissional:</strong> {{professional}}</p>
          <p><strong>Data:</strong> {{date}}</p>
          <p><strong>Hora:</strong> {{time}}</p>
          <p><strong>Barbearia:</strong> {{barbearia}}</p>
          <p><strong>Nome:</strong> {{name}}</p>
          <p><strong>Telefone:</strong> {{phone}}</p>
          <p><strong>Email:</strong> {{email}}</p>
        </div>
        <p><strong>Seu agendamento está marcado para amanhã!</strong></p>
        <p>Por favor, confirme se ainda consegue comparecer ou se precisa reagendar.</p>
        <p>Se precisar cancelar ou alterar, entre em contato conosco com antecedência.</p>
        <p>Visite nosso site: <a href="https://falcaobarbershopv2.web.app">falcaobarbershopv2.web.app</a></p>
        <p>Atenciosamente,<br><strong>Falcão Barbershop</strong></p>
      </div>
    `
  }
};

// Função para processar templates
function processTemplate(template, data) {
  let processed = template;
  Object.keys(data).forEach(key => {
    const regex = new RegExp(`{{${key}}}`, 'g');
    processed = processed.replace(regex, data[key] || '');
  });
  return processed;
}
// Função auxiliar
function timeToMinutes(timeStr) {
  const [h, m] = timeStr.split(':').map(Number);
  return h * 60 + m;
}

exports.createBooking = functions.https.onCall(async (data, context) => {
  const db = admin.firestore();

  const {
    professionalId, dateString, timeString,
    serviceName, professionalName, barbeariaName,
    clientName, clientPhone, clientEmail,
    price, durationMinutes, intervaloMinutos,
    userId, anonymousId,
    usePoints, pointsToSubtract // NOVO
  } = data;

  if (!professionalId || !dateString || !timeString) {
    throw new functions.https.HttpsError('invalid-argument', 'Dados incompletos.');
  }

  return await db.runTransaction(async (transaction) => {
    const snapshot = await db.collection('agendamentos')
      .where('professional', '==', professionalId)
      .where('date', '==', dateString)
      .where('status', 'in', ['pending', 'confirmed'])
      .get();

    const newStart = timeToMinutes(timeString);
    const newEnd = newStart + durationMinutes + intervaloMinutos;

    for (const doc of snapshot.docs) {
      const d = doc.data();
      const bookedStart = timeToMinutes(d.time);
      const bookedEnd = bookedStart + (d.duracao || 0) + (d.intervalo || 0);

      if (newStart < bookedEnd && newEnd > bookedStart) {
        throw new functions.https.HttpsError('already-exists', 'horário indisponível');
      }
      if (userId && d.userId === userId && d.time === timeString) {
        throw new functions.https.HttpsError('already-exists', 'agendamento duplicado');
      }
    }

    // Lê o documento do cliente DENTRO da transaction, se houver userId
    let userRef = null;
    let userSnap = null;
    if (userId) {
      userRef = db.collection('clientes').doc(userId);
      userSnap = await transaction.get(userRef);
    }

    // Cria o agendamento
    const newRef = db.collection('agendamentos').doc();
    transaction.set(newRef, {
      professional: professionalId,
      date: dateString,
      time: timeString,
      service: serviceName,
      professionalName: professionalName,
      barbearia: barbeariaName,
      name: clientName,
      phone: clientPhone,
      email: clientEmail,
      price: price,
      duracao: durationMinutes,
      intervalo: intervaloMinutos,
      status: 'pending',
      userId: userId || null,
      anonymousId: anonymousId || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Pontos — atómico, dentro da mesma transaction
    if (userRef && userSnap && userSnap.exists) {
      const currentPoints = userSnap.data().points || 0;
      let netPoints = 10; // ganha sempre 10 por agendamento

      if (usePoints && pointsToSubtract > 0 && currentPoints >= pointsToSubtract) {
        netPoints -= pointsToSubtract;
      }

      transaction.update(userRef, {
        points: admin.firestore.FieldValue.increment(netPoints),
      });

      const historyRef = userRef.collection('pointsHistory').doc();
      transaction.set(historyRef, {
        type: 'earned',
        description: `Agendamento confirmado: ${serviceName}`,
        points: 10,
        date: admin.firestore.FieldValue.serverTimestamp(),
      });

      if (usePoints && pointsToSubtract > 0 && currentPoints >= pointsToSubtract) {
        const discountHistoryRef = userRef.collection('pointsHistory').doc();
        transaction.set(discountHistoryRef, {
          type: 'spent',
          description: `Desconto aplicado no agendamento`,
          points: -pointsToSubtract,
          date: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }

    return { bookingId: newRef.id };
  });
});

function timeToMinutes(timeStr) {
  const [h, m] = timeStr.split(':').map(Number);
  return h * 60 + m;
}
// Cloud Function para enviar emails
exports.sendEmail = functions.firestore
  
  .document('mail/{mailId}')
  .onCreate(async (snap, context) => {
    const mailData = snap.data();

    console.log('sendEmail triggered for mailId:', context.params.mailId);
    console.log('mailData:', mailData);
    console.log('Environment variables:', {
      EMAIL_USER: process.env.EMAIL_USER ? 'SET' : 'NOT SET',
      EMAIL_PASS: process.env.EMAIL_PASS ? 'SET' : 'NOT SET'
    });

    try {
      const template = emailTemplates[mailData.template];
      if (!template) {
        console.error('Template não encontrado:', mailData.template);
        return;
      }

      const subject = processTemplate(template.subject, mailData);

      console.log('Sending email to:', mailData.to_email, 'subject:', subject);

      const mailOptions = {
        from: `FalcaoBarberShop <${process.env.EMAIL_USER}>`,
        to: mailData.to_email,
        subject: subject
      };

      // Use HTML if available, otherwise use text
      if (template.html) {
        mailOptions.html = processTemplate(template.html, mailData);
      } else if (template.text) {
        mailOptions.text = processTemplate(template.text, mailData);
      }

      const transporter = getTransporter();
      console.log('Transporter created, sending email...');
      const result = await transporter.sendMail(mailOptions);
      console.log('Email enviado com sucesso:', result.messageId);
      console.log('Full result:', JSON.stringify(result, null, 2));

      // Atualizar o documento com status de enviado
      await snap.ref.update({
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp()
      });

    } catch (error) {
      console.error('Erro ao enviar email:', error);

      // Atualizar o documento com erro
      await snap.ref.update({
        status: 'error',
        error: error.message,
        errorAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }
  });



// Função HTTP para testar envio de email (opcional)
exports.testEmail = functions.https.onCall(async (data, context) => {
  // Verificar se o usuário está autenticado (opcional)
  // if (!context.auth) {
  //   throw new functions.https.HttpsError('unauthenticated', 'Usuário não autenticado');
  // }

  try {
    const template = emailTemplates[data.template] || emailTemplates['booking_received'];
    const subject = processTemplate(template.subject, data);

    const mailOptions = {
      from: `FalcaoBarberShop <${functions.config().email.user}>`,
      to: data.to_email,
      subject: subject
    };

    // Use HTML if available, otherwise use text
    if (template.html) {
      mailOptions.html = processTemplate(template.html, data);
    } else if (template.text) {
      mailOptions.text = processTemplate(template.text, data);
    }

    const transporter = getTransporter();
    const result = await transporter.sendMail(mailOptions);
    return { success: true, messageId: result.messageId };

  } catch (error) {
    console.error('Erro no teste de email:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Cloud Function para auto-completar agendamentos confirmados que já passaram da hora
exports.autoCompleteBookings = functions.pubsub
  .schedule('every 5 minutes')
  .timeZone('Europe/Lisbon')
  .onRun(async (context) => {
    console.log('🔄 Auto-complete bookings function started...');
    
    try {
      const now = new Date();
      const nowTimestamp = admin.firestore.Timestamp.now();
      
      // Format current date and time for comparison
      const currentDate = now.toISOString().split('T')[0]; // "YYYY-MM-DD"
      const currentTime = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`; // "HH:MM"
      
      console.log(`📅 Current date: ${currentDate}, time: ${currentTime}`);
      
      // Query for confirmed bookings
      const snapshot = await admin.firestore()
        .collection('agendamentos')
        .where('status', '==', 'confirmed')
        .get();
      
      console.log(`📊 Found ${snapshot.size} confirmed bookings to check`);
      
      if (snapshot.empty) {
        console.log('✅ No confirmed bookings found. Nothing to update.');
        return null;
      }
      
      // Filter bookings that have passed their scheduled time
      const bookingsToComplete = [];
      
      snapshot.forEach(doc => {
        const data = doc.data();
        const bookingDate = data.date || ''; // "YYYY-MM-DD"
        const bookingTime = data.time || '00:00'; // "HH:MM"
        
        // Combine date and time for comparison
        const bookingDateTime = new Date(`${bookingDate}T${bookingTime}:00`);
        
        // Check if booking time has passed
        if (bookingDateTime < now) {
          bookingsToComplete.push({
            id: doc.id,
            ref: doc.ref,
            date: bookingDate,
            time: bookingTime,
            name: data.name || 'Unknown',
            service: data.service || 'Unknown'
          });
        }
      });
      
      console.log(`⏰ Found ${bookingsToComplete.length} bookings that have passed their scheduled time`);
      
      if (bookingsToComplete.length === 0) {
        console.log('✅ No bookings to auto-complete. All confirmed bookings are still in the future.');
        return null;
      }
      
      // Use batch to update all bookings efficiently
      const batch = admin.firestore().batch();
      
      bookingsToComplete.forEach(booking => {
        console.log(`  📝 Marking as completed: ${booking.name} - ${booking.service} (${booking.date} ${booking.time})`);
        batch.update(booking.ref, {
          status: 'completed',
          concludedAt: nowTimestamp
        });
      });
      
      // Commit all updates
      await batch.commit();
      
      console.log(`✅ Auto-update completed: ${bookingsToComplete.length} booking(s) marked as completed.`);
      
      return null;
    } catch (error) {
      console.error('❌ Error in auto-complete bookings function:', error);
      return null;
    }
  });

// Cloud Function para enviar push notification quando um agendamento é criado
exports.sendNewBookingNotification = functions.firestore
  .document('agendamentos/{bookingId}')
  .onCreate(async (snap, context) => {
    const bookingData = snap.data();

    console.log('sendNewBookingNotification triggered for bookingId:', context.params.bookingId);
    console.log('Booking data:', JSON.stringify(bookingData, null, 2));

    try {
      // Buscar todos os usuários admin e barbeiros para notificar
      const usersSnapshot = await admin.firestore()
        .collection('clientes')
        .where('role', 'in', ['admin', 'barbeiro'])
        .get();

      console.log(`Found ${usersSnapshot.size} admin/barbeiro users`);

      if (usersSnapshot.empty) {
        console.log('Nenhum admin ou barbeiro encontrado para notificar');
        return;
      }

      // Coletar todos os FCM tokens
      const tokens = [];
      const usersWithTokens = [];
      usersSnapshot.forEach(doc => {
        const userData = doc.data();
        console.log(`User ${doc.id}: role=${userData.role}, email=${userData.email}, fcmTokens=${userData.fcmTokens ? userData.fcmTokens.length : 0}`);

        if (userData.fcmTokens && Array.isArray(userData.fcmTokens) && userData.fcmTokens.length > 0) {
          tokens.push(...userData.fcmTokens);
          usersWithTokens.push({
            id: doc.id,
            email: userData.email,
            role: userData.role,
            tokenCount: userData.fcmTokens.length
          });
        }
      });

      console.log(`Users with FCM tokens: ${usersWithTokens.length}`);
      console.log('Users with tokens:', JSON.stringify(usersWithTokens, null, 2));
      console.log(`Total FCM tokens found: ${tokens.length}`);

      if (tokens.length === 0) {
        console.log('Nenhum FCM token encontrado - usuários podem não ter feito login recentemente ou tokens expiraram');
        return;
      }
      
      // Preparar a mensagem de notificação
      const message = {
        notification: {
          title: 'Novo Agendamento Recebido',
          body: `${bookingData.name || 'Cliente'} agendou ${bookingData.service || 'um serviço'} para ${bookingData.date || ''} às ${bookingData.time || ''}`,
          icon: '/icons/Icon-192.png',
        },
        data: {
          click_action: '/admin/notificacoes',
          bookingId: context.params.bookingId,
          type: 'new_booking',
          name: bookingData.name || '',
          service: bookingData.service || '',
          date: bookingData.date || '',
          time: bookingData.time || '',
        },
        tokens: tokens,
      };
      
      // Enviar notificação para todos os tokens
      const response = await admin.messaging().sendEachForMulticast(message);
      
      console.log(`Push notifications enviadas com sucesso: ${response.successCount} de ${tokens.length}`);
      
      if (response.failureCount > 0) {
        console.log(`Falhas ao enviar notificações: ${response.failureCount}`);
        
        // Remover tokens inválidos
        const tokensToRemove = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            console.error(`Erro ao enviar para token ${idx}:`, resp.error);
            // Se o token é inválido, adicionar à lista para remoção
            if (resp.error?.code === 'messaging/invalid-registration-token' ||
                resp.error?.code === 'messaging/registration-token-not-registered') {
              tokensToRemove.push(tokens[idx]);
            }
          }
        });
        
        // Remover tokens inválidos dos documentos dos usuários
        if (tokensToRemove.length > 0) {
          console.log(`Removendo ${tokensToRemove.length} tokens inválidos`);
          const batch = admin.firestore().batch();
          
          usersSnapshot.forEach(doc => {
            const userData = doc.data();
            if (userData.fcmTokens && Array.isArray(userData.fcmTokens)) {
              const validTokens = userData.fcmTokens.filter(token => !tokensToRemove.includes(token));
              if (validTokens.length !== userData.fcmTokens.length) {
                batch.update(doc.ref, { fcmTokens: validTokens });
              }
            }
          });
          
          await batch.commit();
          console.log('Tokens inválidos removidos com sucesso');
        }
      }
      
    } catch (error) {
      console.error('Erro ao enviar push notification:', error);
    }
  });
// Cloud Function para enviar lembretes automáticos por email (1h30min e 1 dia antes)
exports.sendAppointmentReminders = functions.pubsub
  .schedule('every 5 minutes')
  .timeZone('Europe/Lisbon')
  .onRun(async () => {
    console.log('⏰ Verificando lembretes de agendamento...');

    const now = new Date();
    const nowTimestamp = admin.firestore.Timestamp.fromDate(now);

    try {
      // Buscar agendamentos confirmados que ainda não receberam lembretes
      const snapshot = await admin.firestore()
        .collection('agendamentos')
        .where('status', '==', 'confirmed')
        .get();

      if (snapshot.empty) {
        console.log('✅ Nenhum agendamento encontrado.');
        return null;
      }

      for (const doc of snapshot.docs) {
        const data = doc.data();

        if (!data.date || !data.time || !data.email) continue;

        const appointmentDateTime = new Date(`${data.date}T${data.time}:00`);
        const diffMinutes = (appointmentDateTime - now) / 60000;
        const diffHours = diffMinutes / 60;
        const diffDays = diffHours / 24;

        // Enviar lembrete 1 dia antes (entre 24h e 23h50min antes)
        if (diffDays <= 1 && diffDays > 0.98 && !data.reminder1DaySent) {
          console.log(`📧 Enviando lembrete de 1 dia para ${data.email}`);

          await admin.firestore().collection('mail').add({
            to_email: data.email,
            template: 'appointment_reminder_1day',
            name: data.name,
            service: data.service,
            professional: data.professional,
            date: data.date,
            time: data.time,
            barbearia: data.barbearia,
            phone: data.phone,
            price: data.price,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          await doc.ref.update({
            reminder1DaySent: true,
            reminder1DaySentAt: nowTimestamp
          });
        }

        // Enviar lembrete 1h30min antes (entre 90min e 85min antes)
        if (diffMinutes <= 90 && diffMinutes > 85 && !data.reminderSent) {
          console.log(`📧 Enviando lembrete de 1h30min para ${data.email}`);

          await admin.firestore().collection('mail').add({
            to_email: data.email,
            template: 'appointment_reminder',
            name: data.name,
            service: data.service,
            professional: data.professional,
            date: data.date,
            time: data.time,
            barbearia: data.barbearia,
            phone: data.phone,
            price: data.price,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          await doc.ref.update({
            reminderSent: true,
            reminderSentAt: nowTimestamp
          });
        }
      }

      console.log('✅ Processo de lembretes concluído.');
      return null;

    } catch (error) {
      console.error('❌ Erro ao enviar lembretes:', error);
      return null;
    }
  });

// Function to update stats when data changes
exports.updateStats = functions.firestore
  .document('{collection}/{docId}')
  .onWrite(async (change, context) => {
    const db = admin.firestore();
    const collection = context.params.collection;

    // Only update stats for relevant collections
    if (['clientes', 'agendamentos'].includes(collection)) {
      try {
        const usersSnap = await db.collection('clientes').get();
        const appointmentsSnap = await db.collection('agendamentos').get();

        await db.collection('stats').doc('home').set({
          totalUsers: usersSnap.size,
          totalAppointments: appointmentsSnap.size,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        console.log('Stats updated successfully');
      } catch (error) {
        console.error('Error updating stats:', error);
      }
    }
  });
