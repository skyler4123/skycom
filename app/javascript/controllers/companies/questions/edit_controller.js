import Companies_Questions_FormController from "controllers/companies/questions/form_controller"

export default class Companies_Questions_EditController extends Companies_Questions_FormController {
  // Depends on BE: Companies::QuestionsController#edit + #update
  // Endpoints: GET /companies/:id/questions/:id/edit.json,
  //            PATCH /companies/:id/questions/:id
  // Docs: docs/EXAMS.md
}
