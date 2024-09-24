const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");

// The Firebase Admin SDK to access Firestore.
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

// Firestore trigger for when a user is added to an esports group
exports.createEsportGroupNotification = onDocumentUpdated("esports_groups/{groupId}", async (event) =>  {
    const newValue = event.data.after.data();
    const previousValue = event.data.before.data();

    // Check if a new member was added to the group
    const newMembers = newValue.members || [];
    const oldMembers = previousValue.members || [];

    // Find the newly added members
    const addedMembers = newMembers.filter((member) => !oldMembers.includes(member));

    const groupId = event.params.groupId;
    const groupName = newValue.groupName;

    const promises = addedMembers.map((memberId) => {
      const notification = {
        title: "Nhóm mới",
        message: `Bạn đã được thêm vào nhóm ${groupName}`,
        type: "esport_group",
        relatedId: groupId,
        timestamp: FieldValue.serverTimestamp(),
        isRead: false,
        userId: memberId,
      };

      // Add notification to the user's subcollection
      return db
        .collection("users")
        .doc(memberId)
        .collection("notifications")
        .add(notification);
    });

    return Promise.all(promises);
  });

// // Firestore trigger for when a user is added to an esports league
// exports.createEsportLeagueNotification = onDocumentUpdated("esports_leagues/{leagueId}", async (change, context) =>  {
//     const newValue = change.after.data();
//     const previousValue = change.before.data();

//     // Check if a new participant was added to the league
//     const newParticipants = newValue.participants || [];
//     const oldParticipants = previousValue.participants || [];

//     // Find the newly added participants
//     const addedParticipants = newParticipants.filter((participant) => !oldParticipants.includes(participant));

//     const leagueId = context.params.leagueId;
//     const leagueName = newValue.name;

//     const promises = addedParticipants.map((participantId) => {
//       const notification = {
//         title: "Giải đấu mới",
//         message: `Bạn đã được thêm vào giải đấu ${leagueName}`,
//         type: "esport_league",
//         relatedId: leagueId,
//         timestamp: db.FieldValue.serverTimestamp(),
//         isRead: false,
//         userId: participantId,
//       };

//       // Add notification to the user's subcollection
//       return db
//         .collection("users")
//         .doc(participantId)
//         .collection("notifications")
//         .add(notification);
//     });

//     return Promise.all(promises);
//   });

// // Firestore trigger for when a notification is created in the user's subcollection
// exports.sendPushNotification = onDocumentCreated("users/{userId}/notifications/{notificationId}", async (event) => {
//     const notificationData = event.data.data().original;
//     const userId = event.params.userId;

//     // Fetch the user's FCM token from Firestore
//     const userDoc = await db.collection("users").doc(userId).get();
//     const fcmToken = userDoc.data()?.fcmToken; // Use optional chaining to avoid errors

//     if (fcmToken && fcmToken.trim() !== "") {
//       const message = {
//         notification: {
//           title: notificationData.title,
//           body: notificationData.message,
//         },
//         token: fcmToken,
//         data: {
//           // Add any additional data you want to send
//           type: notificationData.type,
//           relatedId: notificationData.relatedId,
//           timestamp: notificationData.timestamp,
//           isRead: notificationData.isRead.toString(), // Convert boolean to string if needed
//         },
//       };

//       // Send the push notification via FCM
//       return getMessaging.send(message)
//         .then((response) => {
//           console.log("Successfully sent push notification:", response);
//           return null;
//         })
//         .catch((error) => {
//           console.error("Error sending push notification:", error);
//         });
//     }

//     return null;
//   });