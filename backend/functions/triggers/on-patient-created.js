const functions = require("firebase-functions")
const { db } = require("../config/firebase")

/**
 * Auto-generate de-identified patient profile when admin creates patient
 */
module.exports = functions.firestore.document("patients/{patientId}").onCreate(async (snap, context) => {
  try {
    const patient = snap.data()
    const patientId = context.params.patientId

    // Create de-identified version for public view
    const publicPatient = {
      anonymousId: `Patient #${patientId.substring(0, 8).toUpperCase()}`,
      age: patient.age,
      generalDiagnosis: patient.diagnosis.split(" ")[0], // Just cancer type, not details
      fundingGoal: patient.fundingGoal,
      currentFunding: patient.currentFunding || 0,
      fundingProgress: ((patient.currentFunding || 0) / patient.fundingGoal) * 100,
      priority: patient.priority || 5,
      impactStory: patient.impactStory || "",
      createdAt: patient.createdAt,
      updatedAt: patient.updatedAt,
    }

    // Save to public_patients collection
    await db.collection("public_patients").doc(patientId).set(publicPatient)

    console.log(`Created de-identified profile for patient ${patientId}`)
  } catch (error) {
    console.error("Patient creation trigger error:", error)
  }
})
