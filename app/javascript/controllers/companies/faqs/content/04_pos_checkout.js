export default {
  key: "pos_checkout",
  icon: "point_of_sale",
  title: {
    en: "POS & checkout",
    vi: "POS & thanh toán"
  },
  questions: [
    {
      slug: "pos-prerequisites",
      question: {
        en: "What must be enabled before a cashier can use POS?",
        vi: "Cần bật gì trước khi thu ngân dùng được POS?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Three things must line up: the POS operation must be active at the branch, the cashier's role must be allowed by that operation, and at least one payment method must be active for the branch. The branch also needs products or services with selling prices, and a tax configuration if you charge tax. If the launch icon is disabled, the tooltip names the missing piece instead of failing silently.",
            vi: "Ba điều kiện phải khớp: vận hành POS phải đang hoạt động tại chi nhánh, vai trò của thu ngân phải được vận hành đó cho phép, và ít nhất một phương thức thanh toán phải đang hoạt động cho chi nhánh. Chi nhánh cũng cần sản phẩm hoặc dịch vụ có giá bán, và cấu hình thuế nếu bạn thu thuế. Nếu nút mở bị vô hiệu, chú thích sẽ nêu phần còn thiếu thay vì im lặng."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Operations", vi: "Mở Vận hành" }, path: "company_operations_path" },
            { label: { en: "Open Payment Methods", vi: "Mở Phương thức thanh toán" }, path: "company_payment_method_appointments_path" }
          ]
        }
      ]
    },
    {
      slug: "start-sale-and-scan",
      question: {
        en: "How do I start a sale, scan a barcode, and add a product or service?",
        vi: "Làm sao bắt đầu bán, quét mã vạch và thêm sản phẩm hoặc dịch vụ?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Open POS from Operations, then use the search field at the top of the catalog: it doubles as the barcode input, and F1 focuses it. Type a name or code to search, or scan an exact product code to add one unit immediately. You can also click a product card or a service card, switch categories with the pills, and change the quantity in the cart. A code that is not found shows a message and leaves the cart unchanged.",
            vi: "Mở POS từ Vận hành, sau đó dùng ô tìm kiếm ở đầu danh mục: ô này cũng là ô quét mã vạch, và phím F1 đưa con trỏ vào đó. Gõ tên hoặc mã để tìm, hoặc quét đúng mã sản phẩm để thêm ngay một đơn vị. Bạn cũng có thể bấm thẻ sản phẩm hoặc thẻ dịch vụ, chuyển danh mục bằng các nút tròn, và đổi số lượng trong giỏ. Mã không tìm thấy sẽ hiện thông báo và giỏ hàng không đổi."
          }
        }
      ]
    },
    {
      slug: "parallel-customers",
      question: {
        en: "How do I serve several customers at the same time?",
        vi: "Làm sao phục vụ nhiều khách cùng lúc?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Use New Customer above the catalog to open another cart tab. Each tab keeps its own items, customer, and quantities, so you can pause one sale, serve the next person, and switch back. The tabs live in the browser, so a refresh keeps them but a different browser or tablet does not see them. You cannot close the last open tab, and closing a tab discards its cart after confirmation.",
            vi: "Dùng New Customer phía trên danh mục để mở thêm thẻ giỏ hàng. Mỗi thẻ giữ mặt hàng, khách hàng và số lượng riêng, nên bạn có thể tạm dừng một đơn, phục vụ người tiếp theo rồi quay lại. Các thẻ nằm trong trình duyệt, nên tải lại vẫn còn nhưng trình duyệt hoặc máy tính bảng khác sẽ không thấy. Không thể đóng thẻ cuối cùng, và đóng thẻ sẽ bỏ giỏ hàng sau khi xác nhận."
          }
        }
      ]
    },
    {
      slug: "attach-customer",
      question: {
        en: "How do I attach a customer, and when should I use walk-in?",
        vi: "Làm sao gắn khách hàng và khi nào dùng khách tại quầy?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Use the customer card in the sale panel and search by customer ID, phone number, or name; press Enter to attach the match. If the customer is not registered, leave the sale as Walk-in — it is a valid sale and keeps the receipt clean. Clear removes the attached customer and returns the tab to Walk-in. Attaching a customer is what lets the sale appear in that customer's order history and top-customer reports.",
            vi: "Dùng thẻ khách hàng trong bảng bán và tìm theo mã khách hàng, số điện thoại hoặc tên; nhấn Enter để gắn kết quả. Nếu khách chưa đăng ký, hãy để đơn là Khách tại quầy — đơn vẫn hợp lệ và biên lai vẫn rõ ràng. Clear sẽ bỏ khách đã gắn và đưa thẻ về Khách tại quầy. Gắn khách hàng là cách để đơn xuất hiện trong lịch sử đơn của khách và báo cáo khách hàng hàng đầu."
          }
        }
      ]
    },
    {
      slug: "stock-cap",
      question: {
        en: "Why is the quantity capped by the “in stock” number?",
        vi: "Vì sao số lượng bị giới hạn bởi số “còn hàng”?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "POS sells from one selling pile: the available quantity in the warehouse Skycom chooses for selling, usually the main warehouse and oldest stock first. The cart cannot exceed that available number, and the server rejects an over-stock checkout even if the browser is out of date. The number is available (on hand minus reserved), not on hand, so an unpaid order or event hold can make a product look short. The warehouse name beside the number tells you which pile it is.",
            vi: "POS bán từ một nguồn tồn: số lượng khả dụng trong kho Skycom chọn để bán, thường là kho chính và lô cũ nhất trước. Giỏ hàng không thể vượt số khả dụng đó, và máy chủ sẽ từ chối thanh toán vượt tồn kể cả khi trình duyệt đã cũ. Con số là khả dụng (tồn thực trừ đã giữ), không phải tồn thực, nên một đơn chưa thanh toán hoặc lượt giữ chỗ có thể làm sản phẩm trông thiếu. Tên kho cạnh con số cho biết đang lấy từ nguồn nào."
          }
        }
      ]
    },
    {
      slug: "price-ownership",
      status: "planned",
      question: {
        en: "Who sets the price, and can a cashier override it?",
        vi: "Ai đặt giá và thu ngân có thể sửa giá không?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "The server sets the price from the product or service record; the browser sends only item IDs and quantities, so a tampered cart cannot invent a cheaper price. A cashier cannot override the price at the till today, and there is no open-item or manual-price button. If a one-off price is needed, the current workaround is to create the item in the catalog with the intended price, or handle the difference outside POS. Manager-approved overrides with an audit trail are tracked in the backlog.",
            vi: "Máy chủ đặt giá từ bản ghi sản phẩm hoặc dịch vụ; trình duyệt chỉ gửi mã mặt hàng và số lượng, nên giỏ hàng bị can thiệp không thể tạo ra giá rẻ hơn. Thu ngân hiện không thể sửa giá tại quầy, và không có nút mặt hàng mở hay nhập giá tay. Nếu cần giá một lần, cách hiện tại là tạo mặt hàng trong danh mục với giá mong muốn, hoặc xử lý phần chênh lệch ngoài POS. Việc cho quản lý duyệt sửa giá kèm nhật ký đang được ghi trong backlog."
          }
        }
      ]
    },
    {
      slug: "tax-at-checkout",
      question: {
        en: "How is tax applied at checkout?",
        vi: "Thuế được áp dụng khi thanh toán như thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "POS reads one company-wide tax rate and name from Tax Config, calculates tax on the discounted subtotal, and snapshots both onto the order and invoice. The receipt prints the same snapshot, so a later rate change cannot rewrite an open sale. When the configured rate is zero, the tax row is hidden instead of showing a zero. Mixed tax rates per product and tax-inclusive pricing are not supported yet.",
            vi: "POS đọc một mức thuế và tên thuế chung của công ty từ Cấu hình thuế, tính thuế trên tạm tính sau giảm giá, và sao lưu cả hai vào đơn hàng lẫn hóa đơn. Biên lai in đúng bản sao lưu đó, nên thay đổi thuế sau này không viết lại một đơn đang mở. Khi mức thuế bằng 0, dòng thuế được ẩn thay vì hiện số 0. Hiện chưa hỗ trợ nhiều mức thuế theo sản phẩm hoặc giá đã gồm thuế."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Tax Config", vi: "Mở Cấu hình thuế" }, path: "company_tax_config_path" }
          ]
        }
      ]
    },
    {
      slug: "apply-discount",
      question: {
        en: "How do I apply a discount code?",
        vi: "Làm sao áp dụng mã giảm giá?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Create the order first, then enter the code in the discount field and choose Apply; the field appears only after ORDER because the discount is reserved against a real order. A valid code shows its name and amount off, and the total updates before payment. Remove releases the code, as do void and an abandoned QR payment. The code is consumed only when the invoice is paid, and the receipt shows the discount line when it is greater than zero.",
            vi: "Tạo đơn trước, sau đó nhập mã vào ô giảm giá và chọn Apply; ô này chỉ hiện sau khi bấm ORDER vì mã được giữ trên một đơn thật. Mã hợp lệ hiện tên và số tiền giảm, tổng cập nhật trước khi thanh toán. Remove sẽ giải phóng mã, tương tự khi hủy đơn hoặc bỏ dở thanh toán QR. Mã chỉ bị dùng khi hóa đơn được thanh toán, và biên lai hiện dòng giảm giá khi số tiền lớn hơn 0."
          }
        }
      ]
    },
    {
      slug: "cash-and-qr",
      question: {
        en: "How do cash payments, change, and QR payments work?",
        vi: "Thanh toán tiền mặt, tiền thừa và QR hoạt động thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "The payment buttons come from the payment methods appointed to the branch. For cash, enter the amount received or use a quick-cash button; POS computes the change live before you confirm. For QR, POS shows the code and waits for the gateway confirmation; Cancel while waiting voids the pending transaction and releases the order. A paid sale shows Print Receipt and New Sale, and the payment is recorded against the invoice, not against the cart.",
            vi: "Các nút thanh toán lấy từ phương thức thanh toán được gán cho chi nhánh. Với tiền mặt, nhập số tiền nhận hoặc dùng nút tiền nhanh; POS tính tiền thừa ngay trước khi xác nhận. Với QR, POS hiện mã và chờ cổng thanh toán xác nhận; nút Cancel khi đang chờ sẽ hủy giao dịch đang chờ và giải phóng đơn. Đơn đã thanh toán hiện Print Receipt và New Sale, và khoản thanh toán được ghi vào hóa đơn, không phải vào giỏ hàng."
          }
        }
      ]
    },
    {
      slug: "void-before-payment",
      question: {
        en: "How do I void a sale before payment, and what is released?",
        vi: "Làm sao hủy đơn trước khi thanh toán và những gì được giải phóng?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "After ORDER, use Cancel on the sale panel and confirm the void. Skycom cancels the order in the database, releases its stock reservation, and releases any discount code reserved on it. The tab returns to an editable state or a new sale, depending on where you were. This is a pre-payment void only; a paid sale must go through the refund process, where money and stock reversal are handled separately.",
            vi: "Sau khi bấm ORDER, dùng Cancel trên bảng bán và xác nhận hủy. Skycom hủy đơn trong cơ sở dữ liệu, giải phóng lượng tồn đã giữ và trả lại mã giảm giá đã giữ trên đơn. Thẻ quay về trạng thái sửa được hoặc đơn mới, tùy vị trí. Đây chỉ là hủy trước thanh toán; đơn đã thanh toán phải đi theo quy trình hoàn tiền, nơi việc hoàn tiền và hoàn tồn được xử lý riêng."
          }
        }
      ]
    },
    {
      slug: "receipt-printing",
      question: {
        en: "How do I print a receipt, and what does it contain?",
        vi: "Làm sao in biên lai và biên lai gồm những gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "After payment, choose Print Receipt; Skycom opens the browser print dialog with an 80 mm slip layout containing the branch, time, cashier, lines, subtotal, discount, tax, total, tender, and change. Only the slip is printed, not the whole application. This uses the browser and the operating system's printer, so a thermal receipt printer needs its own driver. There is no direct thermal-printer integration yet.",
            vi: "Sau khi thanh toán, chọn Print Receipt; Skycom mở hộp thoại in của trình duyệt với bố cục phiếu 80 mm gồm chi nhánh, thời gian, thu ngân, các dòng hàng, tạm tính, giảm giá, thuế, tổng, tiền nhận và tiền thừa. Chỉ phiếu được in, không in toàn bộ ứng dụng. Cách này dùng trình duyệt và máy in của hệ điều hành, nên máy in nhiệt cần driver riêng. Hiện chưa có tích hợp trực tiếp với máy in nhiệt."
          }
        }
      ]
    },
    {
      slug: "lock-terminal",
      question: {
        en: "How do I lock and unlock the terminal?",
        vi: "Làm sao khóa và mở khóa quầy?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Use Lock Terminal in the POS header. The lock is enforced by the server, not just by the screen, so checkout and payment return a locked response until someone unlocks it with a valid password. The cart stays behind the overlay, so a short break does not lose the sale. Unlocking requires the signed-in user's password and is recorded as a terminal action.",
            vi: "Dùng Lock Terminal ở đầu màn hình POS. Khóa được máy chủ thực thi, không chỉ trên màn hình, nên thao tác tạo đơn và thanh toán trả về trạng thái khóa cho đến khi có người mở bằng mật khẩu hợp lệ. Giỏ hàng vẫn nằm sau lớp phủ, nên nghỉ ngắn không làm mất đơn. Mở khóa cần mật khẩu của người đang đăng nhập và được ghi nhận là thao tác trên quầy."
          }
        }
      ]
    },
    {
      slug: "pos-limits",
      status: "planned",
      question: {
        en: "What can’t I do in POS today?",
        vi: "Hiện tại POS chưa làm được những gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "POS is a checkout surface, not a full till manager. It does not refund or exchange a paid sale, open a cash drawer, count a float, close a cash shift, override a price, sell an open item, split one payment across methods, work offline, or drive a thermal printer directly. Paid refunds belong to the Refunds workflow, and cash/shift closing belongs to Store Manager. These are deliberate current limits, not hidden buttons, and each is tracked in the backlog.",
            vi: "POS là bề mặt thanh toán, không phải công cụ quản lý quầy đầy đủ. POS không hoàn tiền hay đổi hàng đã thanh toán, không mở ngăn kéo tiền, không đếm tiền đầu ca, không đóng ca tiền mặt, không sửa giá, không bán mặt hàng mở, không tách một khoản thanh toán qua nhiều phương thức, không hoạt động ngoại tuyến và không điều khiển trực tiếp máy in nhiệt. Hoàn tiền đã thanh toán thuộc quy trình Hoàn tiền, còn đóng ca/tiền mặt thuộc Store Manager. Đây là các giới hạn có chủ đích, không phải nút bị ẩn, và mỗi mục đều có trong backlog."
          }
        }
      ]
    }
  ]
}
