import Companies_Exams_FormController from "controllers/companies/exams/form_controller"

export default class Companies_Exams_NewController extends Companies_Exams_FormController {
  // Depends on BE: Companies::ExamsController#new + #create
  // Endpoints: GET /companies/:id/exams/new.json, POST /companies/:id/exams
  // Docs: docs/EXAMS.md
}
