import Companies_Questions_FormController from "controllers/companies/questions/form_controller"

export default class Companies_Questions_NewController extends Companies_Questions_FormController {
  // Depends on BE: Companies::QuestionsController#new + #create
  // Endpoints: GET /companies/:id/questions/new.json, POST /companies/:id/questions
  // Docs: docs/EXAMS.md
}
