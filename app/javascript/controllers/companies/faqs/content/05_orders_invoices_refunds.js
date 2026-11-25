export default {
  key: "orders_invoices_refunds",
  icon: "receipt_long",
  title: {
    en: "Orders, invoices & refunds",
    vi: "Đơn hàng, hóa đơn & hoàn tiền"
  },
  questions: [
    {
      slug: "order-invoice-transaction",
      question: {
        en: "What is the difference between an order, an invoice, and a transaction?",
        vi: "Sự khác nhau giữa đơn hàng, hóa đơn và giao dịch là gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "An order is the commercial header: who bought what, with line items and price snapshots; its total is derived from those lines. An invoice is the money document for that order, with a payment status of unpaid, paid, or voided. A transaction is one payment attempt or receipt against the invoice, with its own method, amount, and gateway reference. In short: the order says what was sold, the invoice says how much is owed, and transactions say what was actually paid.",
            vi: "Đơn hàng là phần đầu thương mại: ai mua gì, với các dòng hàng và giá đã sao lưu; tổng tiền được tính từ các dòng đó. Hóa đơn là chứng từ tiền của đơn, có trạng thái chưa thanh toán, đã thanh toán hoặc đã hủy. Giao dịch là một lần thanh toán hoặc biên nhận trên hóa đơn, có phương thức, số tiền và mã tham chiếu cổng thanh toán riêng. Tóm lại: đơn hàng nói bán gì, hóa đơn nói còn nợ bao nhiêu, giao dịch nói đã trả thực tế bao nhiêu."
          }
        }
      ]
    },
    {
      slug: "order-statuses",
      question: {
        en: "What do order, payment, and fulfilment statuses mean?",
        vi: "Trạng thái đơn hàng, thanh toán và bàn giao có ý nghĩa gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "They are three separate axes, so do not read one as the other. The order workflow follows the commercial lifecycle (draft, pending, confirmed, in progress, completed, cancelled, and so on). Payment lives on the invoice: unpaid, paid, or voided, derived from completed transactions. Fulfilment is about handing goods over: unfulfilled, ready, or handed over, with a channel such as walk-in, click and collect, local delivery, or phone hold. An order can be paid but not handed over, which is exactly what the Store Manager queue highlights.",
            vi: "Đây là ba trục riêng, nên đừng đọc trạng thái này như trạng thái kia. Quy trình đơn hàng theo vòng đời thương mại (nháp, chờ, xác nhận, đang xử lý, hoàn tất, hủy, v.v.). Thanh toán nằm trên hóa đơn: chưa thanh toán, đã thanh toán hoặc đã hủy, được suy ra từ các giao dịch hoàn tất. Bàn giao nói về việc trao hàng: chưa giao, sẵn sàng hoặc đã bàn giao, với kênh như tại quầy, đặt và nhận, giao hàng hoặc giữ qua điện thoại. Một đơn có thể đã thanh toán nhưng chưa bàn giao, và đó chính là điều hàng đợi Store Manager làm nổi bật."
          }
        }
      ]
    },
    {
      slug: "find-a-sale",
      question: {
        en: "Where do I find a sale after checkout?",
        vi: "Tìm một đơn đã bán ở đâu sau khi thanh toán?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Open Orders from the Sales sidebar group. The list supports text search and filters, and a row opens the order detail with its lines, customer, invoice, and receipt action. Invoices has its own list if you need to find the money document directly. From POS, the Orders link in the header opens the same list, so a cashier can hand a past sale to a manager without leaving the till.",
            vi: "Mở Đơn hàng trong nhóm Bán hàng ở thanh bên. Danh sách hỗ trợ tìm kiếm và bộ lọc; bấm một dòng để mở chi tiết đơn với các dòng hàng, khách hàng, hóa đơn và thao tác in biên lai. Hóa đơn có danh sách riêng nếu cần tìm chứng từ tiền trực tiếp. Từ POS, liên kết Orders ở đầu trang mở cùng danh sách đó, nên thu ngân có thể chuyển một đơn cũ cho quản lý mà không rời quầy."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Orders", vi: "Mở Đơn hàng" }, path: "company_orders_path" },
            { label: { en: "Open Invoices", vi: "Mở Hóa đơn" }, path: "company_invoices_path" }
          ]
        }
      ]
    },
    {
      slug: "when-invoice-is-paid",
      question: {
        en: "When does an invoice become paid?",
        vi: "Khi nào hóa đơn chuyển sang đã thanh toán?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "An invoice becomes paid when the sum of its completed transactions reaches or exceeds the invoice total. A pending QR transaction does not count until the gateway confirms it, and a failed or cancelled transaction never counts. The status is derived from the transactions rather than typed by a person, so it cannot drift from the money records. A voided invoice is a separate state from unpaid.",
            vi: "Hóa đơn chuyển sang đã thanh toán khi tổng các giao dịch hoàn tất đạt hoặc vượt tổng tiền hóa đơn. Giao dịch QR đang chờ không được tính cho đến khi cổng thanh toán xác nhận, và giao dịch thất bại hoặc đã hủy không bao giờ được tính. Trạng thái được suy ra từ giao dịch chứ không do người nhập, nên không thể lệch với sổ tiền. Hóa đơn đã hủy là trạng thái riêng, không phải chưa thanh toán."
          }
        }
      ]
    },
    {
      slug: "pay-outside-pos",
      status: "planned",
      question: {
        en: "Can I take payment outside POS?",
        vi: "Có thể thu tiền ngoài POS không?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Not through a guided payment screen today. POS is the only place where Skycom creates the invoice, transactions, stock movement, discount consumption, and receipt in one flow. The Orders and Invoices pages let you review and correct records, but they do not offer a “take payment” button. If money was collected outside the system, record it through the supported payment flow or ask an administrator before editing transaction rows directly. A dedicated payment screen for non-POS orders is tracked in the backlog.",
            vi: "Hiện chưa có màn hình thu tiền có hướng dẫn ngoài POS. POS là nơi duy nhất Skycom tạo hóa đơn, giao dịch, biến động tồn, sử dụng giảm giá và biên lai trong một luồng. Trang Đơn hàng và Hóa đơn cho phép xem và sửa bản ghi, nhưng không có nút “thu tiền”. Nếu tiền đã được thu ngoài hệ thống, hãy ghi nhận qua luồng thanh toán được hỗ trợ hoặc hỏi quản trị viên trước khi sửa trực tiếp các dòng giao dịch. Màn hình thanh toán riêng cho đơn ngoài POS đang được ghi trong backlog."
          }
        }
      ]
    },
    {
      slug: "how-refunds-work",
      question: {
        en: "How do refunds work in Skycom?",
        vi: "Hoàn tiền trong Skycom hoạt động thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "A refund is a request record that follows your company's own refund workflow, bound to a refund category. You link it to the customer, order, invoice, transaction, product, or payment method it concerns, then move it through Submit, Review, and Approve (the default steps). The approval records who decided and when, and the refund list keeps the history. The actual money and stock reversal is a separate manual step outside the request, so approval does not move cash by itself.",
            vi: "Hoàn tiền là bản ghi yêu cầu theo quy trình hoàn tiền của công ty bạn, gắn với một danh mục hoàn tiền. Bạn liên kết yêu cầu với khách hàng, đơn hàng, hóa đơn, giao dịch, sản phẩm hoặc phương thức thanh toán liên quan, rồi chuyển qua các bước Gửi, Xem xét và Duyệt (các bước được tạo sẵn). Việc duyệt ghi lại ai quyết định và khi nào, danh sách hoàn tiền giữ lịch sử. Việc hoàn tiền và hoàn tồn thực tế là bước thủ công riêng bên ngoài yêu cầu, nên duyệt không tự động chuyển tiền."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Refunds", vi: "Mở Hoàn tiền" }, path: "company_refunds_path" }
          ]
        }
      ]
    },
    {
      slug: "refund-no-auto-reversal",
      status: "manual",
      question: {
        en: "Why doesn’t a refund reverse money or stock automatically?",
        vi: "Vì sao hoàn tiền không tự động hoàn tiền hoặc hoàn tồn?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Skycom treats the refund request and the money/stock reversal as different responsibilities. The request captures the reason, approval, and links to the original sale, while the actual reversal depends on how the money was collected and whether the goods can be resold. Automating it would require a gateway refund, a stock receipt, and a re-pricing decision in one transaction. Today the approval is recorded in Skycom and a person completes the reversal; automatic reversal is tracked in the backlog.",
            vi: "Skycom tách yêu cầu hoàn tiền khỏi việc hoàn tiền và hoàn tồn thực tế. Yêu cầu ghi lại lý do, phê duyệt và liên kết đến đơn gốc, còn việc hoàn thực tế phụ thuộc vào cách đã thu tiền và hàng có thể bán lại hay không. Tự động hóa sẽ cần hoàn tiền qua cổng thanh toán, nhập lại tồn và quyết định giá lại trong cùng một giao dịch. Hiện tại phê duyệt được ghi trong Skycom và một người thực hiện hoàn tiền; tự động hoàn tiền đang được ghi trong backlog."
          }
        }
      ]
    },
    {
      slug: "refund-types-and-steps",
      question: {
        en: "What are the refund types and approval steps?",
        vi: "Các loại hoàn tiền và bước phê duyệt là gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "A refund can be cash, product, service, or credit, which tells the team what is being returned or compensated. It is bound to a refund category, and that category owns the workflow, so different refund categories can use different approval steps. The default flow is Submit, Review, and Approve; anyone with update permission on the refund can move it, and every transition is logged. The type does not automatically move money or stock — it tells the approver what the manual follow-up must be.",
            vi: "Hoàn tiền có thể là tiền mặt, sản phẩm, dịch vụ hoặc tín dụng, cho biết đang trả lại hoặc bồi hoàn điều gì. Yêu cầu gắn với một danh mục hoàn tiền, và danh mục sở hữu quy trình, nên các danh mục hoàn tiền khác nhau có thể dùng bước phê duyệt khác nhau. Quy trình tạo sẵn là Gửi, Xem xét và Duyệt; ai có quyền cập nhật yêu cầu hoàn tiền đều có thể chuyển bước, và mọi lần chuyển đều được ghi log. Loại hoàn tiền không tự động chuyển tiền hay hoàn tồn — nó cho người duyệt biết việc cần làm tiếp theo."
          }
        }
      ]
    }
  ]
}
