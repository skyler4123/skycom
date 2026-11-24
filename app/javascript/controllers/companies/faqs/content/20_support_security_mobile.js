export default {
  key: "support_security_mobile",
  icon: "support_agent",
  title: {
    en: "Support, security & mobile",
    vi: "Hỗ trợ, bảo mật & di động"
  },
  questions: [
    {
      slug: "contact-support",
      question: {
        en: "How do I contact Skycom support?",
        vi: "Làm sao liên hệ hỗ trợ Skycom?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Open Help Center from the System group and create a ticket. Include the page or operation, what you expected, what actually happened, and the approximate time; add a screenshot or file if it helps. The ticket goes to the Skycom support pool, and replies and status changes stay on the ticket. Use this FAQ first for how-to questions; use Help Center for a problem with your company's data or access.",
            vi: "Mở Trung tâm hỗ trợ trong nhóm Hệ thống và tạo phiếu. Ghi rõ trang hoặc vận hành, điều bạn mong đợi, điều thực tế xảy ra và thời gian gần đúng; thêm ảnh chụp hoặc tệp nếu hữu ích. Phiếu vào hàng đợi hỗ trợ Skycom, và phản hồi cùng thay đổi trạng thái nằm trên phiếu. Dùng FAQ này trước cho câu hỏi cách làm; dùng Trung tâm hỗ trợ khi có sự cố với dữ liệu hoặc quyền truy cập của công ty."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Help Center", vi: "Mở Trung tâm hỗ trợ" }, path: "company_company_tickets_path" }
          ]
        }
      ]
    },
    {
      slug: "support-ticket-statuses",
      question: {
        en: "What are the support ticket statuses, priorities, and categories?",
        vi: "Trạng thái, mức ưu tiên và danh mục của phiếu hỗ trợ là gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "A support ticket moves through open, in progress, waiting for customer, resolved, closed, or cancelled; only Skycom support changes the status, while you can reply and rate the resolution. Priority is low, medium, high, or urgent. Category is billing, technical, account, feature request, or other. Those fields help route the ticket; they do not change your company's plan or guarantee a response time.",
            vi: "Phiếu hỗ trợ đi qua các trạng thái mở, đang xử lý, chờ khách hàng, đã giải quyết, đã đóng hoặc đã hủy; chỉ hỗ trợ Skycom đổi trạng thái, còn bạn có thể trả lời và đánh giá kết quả. Mức ưu tiên là thấp, trung bình, cao hoặc khẩn cấp. Danh mục là thanh toán, kỹ thuật, tài khoản, yêu cầu tính năng hoặc khác. Các trường này giúp định tuyến phiếu; chúng không đổi gói công ty hay bảo đảm thời gian phản hồi."
          }
        }
      ]
    },
    {
      slug: "company-ticket-versus-internal-ticket",
      question: {
        en: "What is the difference between a Company Ticket and an internal Ticket?",
        vi: "Phiếu công ty và phiếu nội bộ khác nhau thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "A Company Ticket is a support conversation between your company and Skycom, created from Help Center. An internal Ticket is an issue tracker for your own employees, created from the Sales group's Tickets page and following a category workflow. They share some workflow machinery but have different audiences, permissions, and status vocabularies. If you need Skycom to fix an account or data problem, use Help Center; if your team needs to track a task, use Tickets.",
            vi: "Phiếu công ty là cuộc trao đổi hỗ trợ giữa công ty bạn và Skycom, tạo từ Trung tâm hỗ trợ. Phiếu nội bộ là công cụ theo dõi vấn đề cho nhân viên của bạn, tạo từ trang Tickets trong nhóm Bán hàng và theo quy trình của danh mục. Hai loại dùng chung một phần máy quy trình nhưng khác đối tượng, quyền và bộ trạng thái. Nếu cần Skycom sửa tài khoản hoặc dữ liệu, dùng Trung tâm hỗ trợ; nếu nhóm cần theo dõi công việc, dùng Tickets."
          }
        }
      ]
    },
    {
      slug: "audit-permission-changes",
      question: {
        en: "How do I audit permission changes?",
        vi: "Làm sao kiểm tra thay đổi quyền?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Open Permission Logs from the Authorization group. The log records permission-related changes with the actor and time, so you can answer who granted or removed access. Roles and policies themselves show their current state; the log explains how they got there. If a change is missing, confirm the action actually went through the Permissions page rather than being changed directly in a script or console.",
            vi: "Mở Nhật ký quyền trong nhóm Phân quyền. Nhật ký ghi các thay đổi liên quan đến quyền kèm người thực hiện và thời gian, nên có thể trả lời ai đã cấp hoặc thu quyền. Vai trò và chính sách hiện trạng thái hiện tại; nhật ký giải thích cách chúng đến đó. Nếu thiếu một thay đổi, hãy xác nhận thao tác thực sự đi qua trang Phân quyền thay vì bị sửa trực tiếp trong script hoặc console."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Permission Logs", vi: "Mở Nhật ký quyền" }, path: "company_permission_logs_path" }
          ]
        }
      ]
    },
    {
      slug: "mobile-capabilities",
      question: {
        en: "What can I do in the mobile app?",
        vi: "Tôi có thể làm gì trong ứng dụng di động?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "The Android app is an employee companion: Home shows today's shift, attendance state, monthly totals, paid-leave balance, and the latest company notice; Profile shows your own record; Attendance shows your month; Payroll is behind a password gate; Operations lists the consoles you can open. You can check in, file an attendance request, sign out, and upload an avatar. Editing company data, documents, and most management pages stay on web.",
            vi: "Ứng dụng Android là bạn đồng hành cho nhân viên: Home hiện ca hôm nay, trạng thái chấm công, tổng tháng, số ngày phép còn lại và tin công ty mới nhất; Profile hiện hồ sơ của bạn; Attendance hiện tháng của bạn; Bảng lương nằm sau cổng mật khẩu; Operations liệt kê các màn hình bạn mở được. Bạn có thể chấm công vào, gửi yêu cầu chấm công, đăng xuất và tải ảnh đại diện. Sửa dữ liệu công ty, tài liệu và hầu hết trang quản lý vẫn ở web."
          }
        }
      ]
    },
    {
      slug: "mobile-consoles",
      question: {
        en: "Which operation consoles work on mobile?",
        vi: "Những màn hình vận hành nào dùng được trên di động?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "POS, Booking, Reception, Store Manager, and Inventory open in the mobile shell and reuse the web console screens, so the behavior and data match the desktop version. The app's Operations tab shows the operations the employee can access, with the matching Open action. The consoles are responsive rather than separate mobile features, so very wide tables still scroll and the phone layout is denser.",
            vi: "POS, Booking, Reception, Store Manager và Inventory mở trong khung di động và dùng lại màn hình web, nên hành vi và dữ liệu khớp bản desktop. Tab Operations của ứng dụng hiện các vận hành nhân viên được truy cập, kèm thao tác Mở tương ứng. Các màn hình là responsive chứ không phải tính năng di động riêng, nên bảng rất rộng vẫn phải cuộn và bố cục điện thoại dày hơn."
          }
        }
      ]
    },
    {
      slug: "mobile-offline-push-language",
      status: "planned",
      question: {
        en: "Does mobile work offline, send push notifications, or support Vietnamese?",
        vi: "Di động có hoạt động ngoại tuyến, gửi thông báo đẩy hoặc hỗ trợ tiếng Việt không?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "No on all three today. The app has no offline data or sync queue, so a network drop stops the page. It has no push notification permission or push delivery; web notifications stay in the web inbox. The mobile UI is English-only, even though the web app supports English and Vietnamese. These are tracked mobile parity gaps, not settings you can enable.",
            vi: "Cả ba hiện đều chưa. Ứng dụng không có dữ liệu ngoại tuyến hay hàng đợi đồng bộ, nên mất mạng là dừng trang. Ứng dụng không có quyền thông báo đẩy hay dịch vụ gửi thông báo đẩy; thông báo web vẫn nằm trong hộp thư web. Giao diện di động chỉ có tiếng Anh, dù web hỗ trợ tiếng Anh và tiếng Việt. Đây là các khoảng trống đồng bộ di động, không phải cài đặt bạn có thể bật."
          }
        }
      ]
    },
    {
      slug: "language-and-theme",
      question: {
        en: "How do I switch the interface language and dark mode?",
        vi: "Làm sao đổi ngôn ngữ giao diện và chế độ tối?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Use the language button in the header to choose English or Vietnamese; the choice is stored in the browser and the page reloads so every label is re-rendered. Use the moon/sun button for dark mode; the preference is also stored in the browser and applies before the page paints, so there is no flash. Both preferences are per browser profile, not per company account. They apply to the signed-in app, not to the public homepage copy.",
            vi: "Dùng nút ngôn ngữ ở đầu trang để chọn tiếng Anh hoặc tiếng Việt; lựa chọn lưu trong trình duyệt và trang tải lại để mọi nhãn được hiển thị lại. Dùng nút mặt trăng/mặt trời cho chế độ tối; tùy chọn cũng lưu trong trình duyệt và áp dụng trước khi trang vẽ, nên không bị nháy. Cả hai tùy chọn theo hồ sơ trình duyệt, không theo tài khoản công ty. Chúng áp dụng cho ứng dụng đã đăng nhập, không phải nội dung trang chủ công khai."
          }
        }
      ]
    },
    {
      slug: "time-zones",
      question: {
        en: "Why are times shown differently on operation pages, company pages, and admin?",
        vi: "Vì sao giờ hiển thị khác nhau ở trang vận hành, trang công ty và trang quản trị?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Times are stored and sent as UTC, then rendered in the clock that owns the context. Operation pages use the branch or warehouse clock, because that is where the work happens; company pages use the company clock; admin pages use UTC. A receipt printed at a branch therefore shows the branch's local time even if the head office is in another time zone. If a time looks off, check the location's timezone before assuming the record is wrong.",
            vi: "Giờ được lưu và gửi dưới dạng UTC, rồi hiển thị theo đồng hồ của ngữ cảnh. Trang vận hành dùng giờ chi nhánh hoặc kho, vì công việc diễn ra ở đó; trang công ty dùng giờ công ty; trang quản trị dùng UTC. Vì vậy biên lai in tại chi nhánh hiện giờ địa phương của chi nhánh kể cả khi trụ sở ở múi giờ khác. Nếu giờ trông sai, hãy kiểm tra múi giờ của địa điểm trước khi cho rằng bản ghi sai."
          }
        }
      ]
    }
  ]
}
