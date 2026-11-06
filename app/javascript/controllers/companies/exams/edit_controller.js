import Companies_Exams_FormController from "controllers/companies/exams/form_controller"

export default class Companies_Exams_EditController extends Companies_Exams_FormController {
  // Depends on BE: Companies::ExamsController#edit + #update
  // Endpoints: GET /companies/:id/exams/:id/edit.json,
  //            PATCH /companies/:id/exams/:id
  // Docs: docs/EXAMS.md
}
