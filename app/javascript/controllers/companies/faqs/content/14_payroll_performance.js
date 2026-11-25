export default {
  key: "payroll_performance",
  icon: "payments",
  title: {
    en: "Payroll & performance",
    vi: "Bảng lương & hiệu suất"
  },
  questions: [
    {
      slug: "payroll-calculator-or-record",
      question: {
        en: "Is Skycom a payroll calculator or a payroll record?",
        vi: "Skycom là công cụ tính lương hay nơi lưu bảng lương?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "The intended design is a payroll record: Skycom exposes attendance and salary inputs, stores the finished figures, and lets you review, approve, and pay them. Today a draft generator also derives amounts from salary, allowance, overtime, and configured rates, which is a temporary convenience rather than a full payroll engine. Skycom does not file taxes or maintain jurisdiction-specific payroll law. The documented direction is client-calculated results stored back into Skycom.",
            vi: "Thiết kế dự kiến là nơi lưu bảng lương: Skycom cung cấp dữ liệu chấm công và lương đầu vào, lưu kết quả cuối cùng, và cho phép xem, duyệt và chi trả. Hiện một bộ tạo bản nháp cũng tính số tiền từ lương, phụ cấp, tăng ca và mức cấu hình, đây là tiện ích tạm thời chứ không phải công cụ tính lương đầy đủ. Skycom không khai thuế hay duy trì luật lương riêng từng khu vực. Hướng đã ghi là khách hàng tự tính rồi lưu kết quả vào Skycom."
          }
        }
      ]
    },
    {
      slug: "generate-payroll-month",
      question: {
        en: "How do I generate a payroll month?",
        vi: "Làm sao tạo bảng lương cho một tháng?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Open Payroll Data, choose the month, and select Generate. Skycom reads the month's attendance summaries, the employees selected in Payroll Config, and each employee's salary and allowance, then creates or updates one draft payroll per employee and month. Existing rows are updated rather than duplicated. Review the drafts before changing their status; a month with no attendance summary produces no rows.",
            vi: "Mở Dữ liệu bảng lương, chọn tháng và bấm Tạo. Skycom đọc bản tổng hợp chấm công của tháng, nhân viên được chọn trong Cấu hình bảng lương, cùng lương và phụ cấp của từng người, rồi tạo hoặc cập nhật một bản nháp cho mỗi nhân viên và tháng. Dòng đã có sẽ được cập nhật chứ không nhân bản. Hãy xem bản nháp trước khi đổi trạng thái; tháng không có bản tổng hợp chấm công sẽ không tạo dòng nào."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Payroll Data", vi: "Mở Dữ liệu bảng lương" }, path: "company_payroll_path" }
          ]
        }
      ]
    },
    {
      slug: "payroll-statuses",
      question: {
        en: "What do draft, approved, and paid mean?",
        vi: "Nháp, đã duyệt và đã trả có ý nghĩa gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Draft is the working state: the figures can still change and the row is not committed. Approved means a reviewer accepted the figures for payment, and paid means the money was disbursed and the row is history. The status change is explicit; generating again does not silently mark a month approved or paid. Approved and paid rows should be treated as frozen, which is why the current editor only permits status and notes.",
            vi: "Nháp là trạng thái làm việc: số liệu còn có thể đổi và dòng chưa được chốt. Đã duyệt nghĩa là người xem đã chấp nhận số liệu để chi trả, còn đã trả nghĩa là tiền đã được chi và dòng đã thành lịch sử. Việc đổi trạng thái là rõ ràng; tạo lại không âm thầm đánh dấu tháng đã duyệt hay đã trả. Dòng đã duyệt và đã trả nên được coi là đóng băng, vì vậy trình sửa hiện tại chỉ cho đổi trạng thái và ghi chú."
          }
        }
      ]
    },
    {
      slug: "edit-payroll-amounts",
      status: "planned",
      question: {
        en: "Can I edit payroll amounts?",
        vi: "Có thể sửa số tiền bảng lương không?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Not from the web editor today. The payroll row exposes status and notes; the money fields are produced by the generator and the editor does not accept them. That is a gap for teams that calculate payroll outside Skycom and need to post the finished figures back. The intake path for client-calculated amounts, draft-only editing, and an audit trail is tracked in the Payroll backlog section.",
            vi: "Hiện chưa sửa được từ trình sửa trên web. Dòng bảng lương chỉ mở trạng thái và ghi chú; các trường tiền do bộ tạo sinh ra và trình sửa không nhận. Đây là khoảng trống cho nhóm tính lương ngoài Skycom và cần nhập kết quả cuối vào. Đường nhập số tiền do khách tính, chỉ sửa khi còn nháp và nhật ký thay đổi đang được ghi trong mục Bảng lương của backlog."
          }
        }
      ]
    },
    {
      slug: "who-sees-payroll",
      question: {
        en: "Who can see payroll, and why does mobile ask for a password?",
        vi: "Ai xem được bảng lương và vì sao di động hỏi mật khẩu?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Payroll access follows the normal payroll permission: the employee can see their own record through My Profile → Payroll, and managers or administrators need the payroll policy for the company-wide list. Mobile adds a password gate before showing the employee's own payroll, and the unlock lasts five minutes per company. The gate protects salary figures on a shared or unlocked phone; it does not replace the server-side permission check.",
            vi: "Quyền xem bảng lương theo chính sách bảng lương thông thường: nhân viên xem bản ghi của mình qua My Profile → Payroll, còn quản lý hoặc quản trị viên cần chính sách bảng lương cho danh sách toàn công ty. Di động thêm cổng mật khẩu trước khi hiện bảng lương của chính nhân viên, và lần mở khóa kéo dài năm phút cho mỗi công ty. Cổng này bảo vệ số tiền lương trên điện thoại dùng chung hoặc đang mở; nó không thay thế kiểm tra quyền phía máy chủ."
          }
        }
      ]
    },
    {
      slug: "what-kpi-measures",
      question: {
        en: "What does KPI measure today?",
        vi: "KPI hiện đo lường gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "KPI v1 measures paid orders per employee: how many paid orders an employee is credited with, and the revenue those orders represent. It is a visibility tool, not a bonus engine. Scores are computed on demand for a date range, so changing a rule changes the next view without rewriting history. Tasks, projects, attendance, and manual metrics are not part of v1; they would be added as new metric classes.",
            vi: "KPI v1 đo đơn hàng đã thanh toán theo nhân viên: nhân viên được ghi nhận bao nhiêu đơn đã trả và doanh thu của các đơn đó. Đây là công cụ nhìn nhận, không phải công cụ tính thưởng. Điểm được tính khi xem theo khoảng ngày, nên đổi quy tắc sẽ đổi lần xem tiếp theo mà không viết lại lịch sử. Công việc, dự án, chấm công và chỉ số nhập tay không thuộc v1; chúng sẽ được thêm như các lớp chỉ số mới."
          }
        }
      ]
    },
    {
      slug: "kpi-attribution",
      question: {
        en: "How is an order credited to an employee, and what happens to unattributed orders?",
        vi: "Đơn hàng được ghi công cho nhân viên thế nào và đơn không có nhân viên ra sao?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "The order stores one credited employee, which is not always the creator. POS sets the signed-in employee, and the web order form exposes an employee picker that defaults to the signed-in person. Historical orders with no employee stay unattributed: they are shown in a separate leaderboard line and excluded from employee scores, so a low score caused by missing attribution is visible instead of hidden. One order cannot be split across employees.",
            vi: "Đơn hàng lưu một nhân viên được ghi công, không nhất thiết là người tạo. POS đặt nhân viên đang đăng nhập, và biểu mẫu đơn trên web có bộ chọn nhân viên mặc định là người đang đăng nhập. Đơn cũ không có nhân viên sẽ ở trạng thái chưa gán: hiện ở một dòng riêng trên bảng xếp hạng và bị loại khỏi điểm nhân viên, nên điểm thấp do thiếu ghi công sẽ hiện ra thay vì bị che. Một đơn không thể chia cho nhiều nhân viên."
          }
        }
      ]
    },
    {
      slug: "kpi-targets-periods",
      question: {
        en: "How do KPI targets, weights, and periods work?",
        vi: "Mục tiêu, trọng số và kỳ KPI hoạt động thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Each KPI rule has a metric, a direction (higher or lower is better), a period, an optional target, a weight, and optional category/branch/department/role scope. Achievement is actual divided by target, or target divided by actual for lower-is-better metrics, uncapped and rounded to one decimal; a rule without a target is shown but excluded from the composite. The composite is the weighted average of the scored rules. Periods include this month, last month, this quarter, last quarter, this year, and a custom range.",
            vi: "Mỗi quy tắc KPI có chỉ số, hướng (cao hơn hoặc thấp hơn là tốt), kỳ, mục tiêu tùy chọn, trọng số và phạm vi tùy chọn theo danh mục/chi nhánh/phòng ban/vai trò. Mức đạt là thực tế chia mục tiêu, hoặc mục tiêu chia thực tế với chỉ số thấp-hơn-tốt, không giới hạn trần và làm tròn một chữ số; quy tắc không có mục tiêu vẫn hiện nhưng không vào điểm tổng hợp. Điểm tổng hợp là trung bình có trọng số của các quy tắc được chấm. Kỳ gồm tháng này, tháng trước, quý này, quý trước, năm nay và khoảng tùy chọn."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Performance", vi: "Mở Hiệu suất" }, path: "company_performance_index_path" },
            { label: { en: "Open KPI Settings", vi: "Mở Cấu hình KPI" }, path: "company_kpi_configs_path" }
          ]
        }
      ]
    },
    {
      slug: "kpi-pay-link",
      status: "planned",
      question: {
        en: "Does KPI affect pay or bonuses?",
        vi: "KPI có ảnh hưởng đến lương hoặc thưởng không?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "No. KPI is a visibility tool: it scores paid orders per employee for a selected period, with no result snapshots, bonus calculation, commission, or payroll link. A manager can use the scorecard in a review, but changing a payroll row is a separate action and is not automatic. Compensation automation and commission are tracked in the ERP backlog, not in KPI v1.",
            vi: "Không. KPI là công cụ nhìn nhận: chấm điểm đơn đã thanh toán theo nhân viên trong kỳ đã chọn, không có ảnh chụp kết quả, tính thưởng, hoa hồng hay liên kết bảng lương. Quản lý có thể dùng bảng điểm khi đánh giá, nhưng sửa dòng bảng lương là thao tác riêng và không tự động. Tự động hóa lương thưởng và hoa hồng nằm trong backlog ERP, không thuộc KPI v1."
          }
        }
      ]
    }
  ]
}
