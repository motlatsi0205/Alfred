// Import the functions you need from the SDKs you need
import { initializeApp } from "https://www.gstatic.com/firebasejs/12.3.0/firebase-app.js";
import { getAnalytics } from "https://www.gstatic.com/firebasejs/12.3.0/firebase-analytics.js";

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyD4DTT_TrUFWX_YGTJnghI07Nj676-UQDw",
  authDomain: "alfred-a4a64.firebaseapp.com",
  projectId: "alfred-a4a64",
  storageBucket: "alfred-a4a64.firebasestorage.app",
  messagingSenderId: "257127190595",
  appId: "1:257127190595:web:0264fb1d2e0c753fa544f6",
  measurementId: "G-JSPFMMD0V9"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);

export { app, analytics };