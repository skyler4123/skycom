export default {
  key: "purchases_workflows_tickets",
  icon: "shopping_cart",
  title: {
    en: "Purchases, workflows & internal tickets",
    vi: "Mua hàng, quy trình & phiếu nội bộ"
  },
  questions: [
    {
      slug: "purchase-versus-sales-order",
      question: {
        en: "What is a purchase request, and how is it different from a sales order?",
        vi: "Yêu cầu mua hàng là gì và khác đơn bán hàng thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "A purchase is money going out: an employee asks to buy goods or services for the company, and the request moves through an approval workflow. A sales order is money coming in: a customer buys from you, and the order flows through payment and fulfilment. Purchases have suppliers, needed-by dates, and line items; sales orders have customers, invoices, and stock reservations. Both use line items with price snapshots, but they are separate records with separate permissions.",
            vi: "Mua hàng là tiền đi ra: nhân viên xin mua hàng hoặc dịch vụ cho công ty, và yêu cầu đi qua quy trình phê duyệt. Đơn bán hàng là tiền đi vào: khách mua từ bạn, và đơn đi qua thanh toán và bàn giao. Mua hàng có nhà cung cấp, ngày cần và dòng hàng; đơn bán có khách hàng, hóa đơn và lượng tồn giữ. Cả hai đều dùng dòng hàng có giá sao lưu, nhưng là bản ghi riêng với quyền riêng."
          }
        }
      ]
    },
    {
      slug: "default-purchase-steps",
      question: {
        en: "What are the default purchase steps?",
        vi: "Các bước mua hàng mặc định là gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Each purchase category starts with a workflow named after the category, with four steps: Submit, Manager Approval, Buy, and Complete. A new purchase binds to its category's workflow and starts at Submit with a pending status. Approving a step moves the pointer forward; approving the last step completes the purchase. Your company can edit the step names and order in Workflows, and different purchase categories can use different flows.",
            vi: "Mỗi danh mục mua hàng tạo sẵn một quy trình mang tên danh mục với bốn bước: Gửi, Quản lý duyệt, Mua và Hoàn tất. Đơn mua mới gắn với quy trình của danh mục và bắt đầu ở bước Gửi với trạng thái chờ. Duyệt một bước sẽ đưa con trỏ tiến lên; duyệt bước cuối sẽ hoàn tất đơn mua. Công ty có thể sửa tên và thứ tự bước trong Quy trình, và các danh mục mua hàng khác nhau có thể dùng quy trình khác nhau."
          }
        }
      ]
    },
    {
      slug: "who-can-approve",
      question: {
        en: "Who can approve, reject, or rework a step?",
        vi: "Ai có thể duyệt, từ chối hoặc trả lại một bước?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Anyone with update permission on the purchase can move it, regardless of step name. There are no per-step roles: the step names describe the intent, while your permission rules decide access. Rejecting ends the workflow as cancelled; rework sends the record back to an earlier step you choose. The approval log records the actor, outcome, note, and the step it moved from and to, so a step name is never the only evidence of who approved.",
            vi: "Ai có quyền cập nhật đơn mua đều có thể chuyển bước, bất kể tên bước. Không có vai trò riêng cho từng bước: tên bước mô tả ý định, còn quy tắc phân quyền quyết định quyền truy cập. Từ chối sẽ kết thúc quy trình với trạng thái đã hủy; trả lại sẽ đưa bản ghi về một bước trước đó do bạn chọn. Nhật ký phê duyệt ghi người thực hiện, kết quả, ghi chú và bước đi từ đâu đến đâu, nên tên bước không bao giờ là bằng chứng duy nhất về người đã duyệt."
          }
        }
      ]
    },
    {
      slug: "purchase-audit-trail",
      question: {
        en: "Where can I see the audit trail?",
        vi: "Xem nhật ký thay đổi ở đâu?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Open the purchase and use its workflow history. Every transition writes a step log with the actor, the outcome (submitted, approved, rejected, or rework), the note, and the from/to steps. The purchase detail also shows the current step and the line items, so you can reconstruct both what was approved and what was bought. Internal tickets keep the same kind of workflow log plus a ticket-specific log for assignment and lifecycle events.",
            vi: "Mở đơn mua và dùng phần lịch sử quy trình. Mỗi lần chuyển bước ghi một log với người thực hiện, kết quả (gửi, duyệt, từ chối hoặc trả lại), ghi chú và bước đi/đến. Chi tiết đơn mua cũng hiện bước hiện tại và các dòng hàng, nên có thể dựng lại cả việc đã duyệt gì và đã mua gì. Phiếu nội bộ giữ cùng loại nhật ký quy trình, thêm nhật ký riêng cho việc gán người và vòng đời phiếu."
          }
        }
      ]
    },
    {
      slug: "purchase-completion-stock",
      question: {
        en: "What happens when a purchase is completed?",
        vi: "Điều gì xảy ra khi đơn mua hoàn tất?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "The final workflow approval triggers the stock bridge: Skycom creates a received Stock Import and add rows in the destination warehouse ledger, so on hand increases through the normal stock services rather than a direct write. The purchase must have a destination warehouse and at least one line with a product for the bridge to land goods. The purchase then shows as completed, and the stock import is visible in the warehouse's inbound history.",
            vi: "Lần duyệt cuối của quy trình kích hoạt cầu nối tồn kho: Skycom tạo một phiếu nhập đã nhận và các dòng add trong sổ kho đích, nên tồn thực tăng qua các dịch vụ tồn kho chuẩn thay vì ghi trực tiếp. Đơn mua phải có kho đích và ít nhất một dòng có sản phẩm thì hàng mới vào được. Sau đó đơn mua hiện là đã hoàn tất, và phiếu nhập xuất hiện trong lịch sử nhập của kho."
          }
        }
      ]
    },
    {
      slug: "purchase-did-not-increase-stock",
      question: {
        en: "Why didn’t stock increase after final approval?",
        vi: "Vì sao duyệt bước cuối mà tồn kho không tăng?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Check four things: the purchase is really on its final step and completed, it has a destination warehouse, at least one line has a product, and the stock bridge has not already run for that line. A purchase with only free-text items or no warehouse can complete without creating stock. If the goods were received in a different warehouse, the increase is there, not in the warehouse you are looking at. The purchase detail and the warehouse inbound list are the two places to compare.",
            vi: "Kiểm tra bốn điều: đơn mua thực sự ở bước cuối và đã hoàn tất, có kho đích, ít nhất một dòng có sản phẩm, và cầu nối tồn kho chưa chạy cho dòng đó. Đơn chỉ có mặt hàng nhập tay hoặc không có kho vẫn hoàn tất mà không tạo tồn. Nếu hàng được nhận ở kho khác, phần tăng nằm ở đó chứ không phải kho bạn đang xem. Chi tiết đơn mua và danh sách nhập của kho là hai nơi để đối chiếu."
          }
        }
      ]
    },
    {
      slug: "edit-workflow",
      question: {
        en: "How do I edit a workflow, and why is it bound to a category?",
        vi: "Làm sao sửa quy trình và vì sao nó gắn với danh mục?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Open Workflows, choose the workflow, and edit its name or step list; each category owns exactly one workflow. The category is the bridge because it already owns the record's fields and table layout: one category means one consistent process. Records keep their current step and audit history, while the workflow definition changes for the category. Use rework or a new record when a live item must follow a different path.",
            vi: "Mở Quy trình, chọn quy trình và sửa tên hoặc danh sách bước; mỗi danh mục sở hữu đúng một quy trình. Danh mục là cầu nối vì nó đã sở hữu trường và bố cục bảng của bản ghi: một danh mục nghĩa là một quy trình nhất quán. Bản ghi giữ bước hiện tại và lịch sử, còn định nghĩa quy trình thay đổi cho danh mục. Dùng trả lại hoặc tạo bản ghi mới khi một mục đang sống phải đi theo đường khác."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Workflows", vi: "Mở Quy trình" }, path: "company_workflows_path" }
          ]
        }
      ]
    },
    {
      slug: "internal-ticket",
      question: {
        en: "What is an internal Ticket?",
        vi: "Phiếu nội bộ là gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "An internal Ticket is an employee issue tracker inside your company: an IT request, a maintenance problem, an internal approval, or a task that needs an owner. It belongs to a category, follows that category's ticket workflow, and supports an assignee, comments, and a lifecycle log. It is not a support ticket to Skycom; for that, use the Help Center. The two share workflow machinery but serve different audiences.",
            vi: "Phiếu nội bộ là công cụ theo dõi vấn đề của nhân viên trong công ty: yêu cầu IT, sự cố bảo trì, phê duyệt nội bộ hoặc công việc cần người phụ trách. Phiếu thuộc một danh mục, theo quy trình phiếu của danh mục đó, và hỗ trợ người được gán, bình luận và nhật ký vòng đời. Đây không phải phiếu hỗ trợ gửi Skycom; muốn gửi Skycom, dùng Trung tâm hỗ trợ. Hai loại dùng chung máy quy trình nhưng phục vụ đối tượng khác nhau."
          }
        }
      ]
    },
    {
      slug: "suppliers",
      question: {
        en: "How do suppliers fit into purchases?",
        vi: "Nhà cung cấp liên quan đến mua hàng thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "A supplier is a company-scoped record you can attach to a purchase, set as a product's default supplier, and use when the Inventory console creates a reorder. It keeps purchasing history tied to a real party instead of a free-text name. Suppliers do not log in and do not receive a portal in this version; they are reference data for your team. If a supplier is missing at reorder time, Skycom falls back to the product default or asks you to pick one.",
            vi: "Nhà cung cấp là bản ghi trong công ty mà bạn có thể gắn vào đơn mua, đặt làm nhà cung cấp mặc định của sản phẩm, và dùng khi màn hình Inventory tạo đơn đặt lại. Nó giữ lịch sử mua hàng gắn với một bên thật thay vì tên nhập tay. Nhà cung cấp không đăng nhập và không có cổng riêng trong phiên bản này; đây là dữ liệu tham chiếu cho nhóm của bạn. Nếu thiếu nhà cung cấp khi đặt lại, Skycom dùng mặc định của sản phẩm hoặc yêu cầu bạn chọn."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Suppliers", vi: "Mở Nhà cung cấp" }, path: "company_suppliers_path" }
          ]
        }
      ]
    }
  ]
}
