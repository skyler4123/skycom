export default {
  key: "inventory_stock",
  icon: "warehouse",
  title: {
    en: "Inventory & stock",
    vi: "Tồn kho & kho"
  },
  questions: [
    {
      slug: "on-hand-reserved-available",
      question: {
        en: "What do on hand, reserved, and available mean?",
        vi: "Tồn thực, đã giữ và khả dụng có ý nghĩa gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "On hand is the physical quantity recorded for one product in one warehouse. Reserved is the quantity already promised to an unpaid order or an active event hold. Available is on hand minus reserved, never shown below zero. Sales and transfers can only use available quantity, so a product can show stock and still refuse to sell if the rest is reserved. A stock row is always per warehouse and product; there is no single company-wide on-hand number.",
            vi: "Tồn thực là số lượng vật lý được ghi cho một sản phẩm trong một kho. Đã giữ là số lượng đã hứa cho một đơn chưa thanh toán hoặc một lượt giữ chỗ đang hoạt động. Khả dụng là tồn thực trừ đã giữ, không bao giờ hiển thị dưới 0. Bán hàng và chuyển kho chỉ dùng được phần khả dụng, nên sản phẩm có thể còn tồn nhưng vẫn từ chối bán nếu phần còn lại đang bị giữ. Dòng tồn luôn theo từng kho và sản phẩm; không có một con số tồn chung toàn công ty."
          }
        }
      ]
    },
    {
      slug: "stock-per-warehouse",
      question: {
        en: "Why is stock tracked per warehouse instead of per branch?",
        vi: "Vì sao tồn kho theo từng kho thay vì theo chi nhánh?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "A branch is where you sell; a warehouse is where goods physically sit. One branch can be served by several warehouses, and one warehouse can serve several branches, so a single branch-level quantity would be ambiguous. Keeping stock per warehouse lets every import, export, transfer, adjustment, and count name a real source and destination. The branch sees availability through the stock chosen for selling, but the ledger stays in the warehouse.",
            vi: "Chi nhánh là nơi bạn bán; kho là nơi hàng thực sự nằm. Một chi nhánh có thể được phục vụ bởi nhiều kho, và một kho có thể phục vụ nhiều chi nhánh, nên một con số tồn theo chi nhánh sẽ mơ hồ. Giữ tồn theo kho cho phép mọi phiếu nhập, xuất, chuyển, điều chỉnh và kiểm kê nêu rõ nguồn và đích thật. Chi nhánh thấy lượng khả dụng qua nguồn tồn được chọn để bán, nhưng sổ kho vẫn nằm ở kho."
          }
        }
      ]
    },
    {
      slug: "receive-stock",
      question: {
        en: "How do I receive stock?",
        vi: "Làm sao nhập kho?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Receiving stock creates a Stock Import and an add row in the warehouse ledger; it does not edit the quantity directly. Open the Inventory console for the warehouse, choose Receive, search for the item, enter the quantity, and optionally choose the supplier and put-away location. Posting the receipt raises on hand immediately and the document appears under Inbound.",
            vi: "Nhập kho tạo một phiếu nhập (Stock Import) và một dòng add trong sổ kho của kho; hệ thống không sửa trực tiếp số lượng. Mở màn hình Inventory của kho, chọn Receive, tìm mặt hàng, nhập số lượng, rồi chọn nhà cung cấp và vị trí lưu hàng nếu có. Khi ghi nhận phiếu, tồn thực tăng ngay và phiếu xuất hiện trong mục Inbound."
          }
        },
        {
          type: "steps",
          items: [
            { en: "Open Operations → Inventory for the warehouse.", vi: "Mở Operations → Inventory cho kho." },
            { en: "Select Receive and search for the item.", vi: "Chọn Receive và tìm mặt hàng." },
            { en: "Enter the quantity, supplier, location, and note.", vi: "Nhập số lượng, nhà cung cấp, vị trí và ghi chú." },
            { en: "Select Post receipt.", vi: "Chọn Post receipt." }
          ]
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Operations", vi: "Mở Vận hành" }, path: "company_operations_path" }
          ]
        }
      ]
    },
    {
      slug: "transfer-and-export",
      question: {
        en: "How do I transfer stock, or export it out of the company?",
        vi: "Làm sao chuyển kho hoặc xuất kho ra khỏi công ty?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Open Transfer out in the Inventory console and choose a mode. Another warehouse asks for the destination and starts a two-phase transfer: the source available quantity drops immediately as a hold, and the destination on hand rises only when someone marks it received. Leaving the company asks for a reference note and records an export, which removes the goods from the source ledger. Both modes create a document you can find under Outbound.",
            vi: "Mở Transfer out trong màn hình Inventory và chọn chế độ. Chuyển sang kho khác cần kho đích và bắt đầu luồng hai bước: lượng khả dụng ở nguồn giảm ngay như một khoản giữ, còn tồn thực ở đích chỉ tăng khi có người đánh dấu đã nhận. Xuất ra khỏi công ty cần ghi chú tham chiếu và tạo phiếu xuất, đưa hàng ra khỏi sổ kho nguồn. Cả hai chế độ đều tạo chứng từ trong mục Outbound."
          }
        }
      ]
    },
    {
      slug: "adjust-stock",
      question: {
        en: "How do I correct stock with a reason?",
        vi: "Làm sao điều chỉnh tồn với lý do?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Use Adjust on a stock row, enter the new on-hand number, and choose a reason: Count correction, Damage, Found, or Other. Add a note when the reason needs context. Skycom sets on hand to the new number, leaves reserved untouched, and blocks a value below the reserved quantity with a named error. The adjustment is stored as a document, so the correction has an audit trail instead of silently changing a number.",
            vi: "Dùng Adjust trên một dòng tồn, nhập số tồn thực mới và chọn lý do: Điều chỉnh kiểm kê, Hư hỏng, Tìm thấy hoặc Khác. Thêm ghi chú khi lý do cần ngữ cảnh. Skycom đặt tồn thực thành số mới, giữ nguyên phần đã giữ, và chặn giá trị thấp hơn số đã giữ bằng lỗi nêu rõ. Điều chỉnh được lưu thành chứng từ, nên lần sửa có nhật ký thay vì âm thầm đổi số."
          }
        }
      ]
    },
    {
      slug: "reorder-point",
      question: {
        en: "What is the reorder point, and what does Reorder create?",
        vi: "Điểm đặt hàng lại là gì và nút Reorder tạo ra gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "The reorder point is the level where a row becomes Low: an active ReorderRule's minimum plus safety stock, or the company default of 10 when no rule exists. Reorder appears on Low and Out rows. It creates or reuses one open purchase draft for that product and warehouse, with the shortfall as the default quantity, and approval/receipt continue on the purchase screens. Pressing the action again opens the same draft instead of creating duplicates.",
            vi: "Điểm đặt hàng lại là ngưỡng mà dòng tồn trở thành Thấp: mức tối thiểu của ReorderRule đang hoạt động cộng tồn an toàn, hoặc mặc định công ty là 10 khi chưa có quy tắc. Nút Reorder xuất hiện trên dòng Thấp và Hết. Nó tạo hoặc dùng lại một đơn mua nháp đang mở cho sản phẩm và kho đó, với số lượng mặc định là phần thiếu; việc duyệt và nhận hàng tiếp tục trên màn hình mua hàng. Bấm lại sẽ mở đúng đơn nháp đó thay vì tạo trùng."
          }
        }
      ]
    },
    {
      slug: "cycle-count",
      question: {
        en: "How does a cycle count work, and what happens to variance?",
        vi: "Kiểm kê hoạt động thế nào và chênh lệch được xử lý ra sao?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Start a count from the Inventory console; only one count can be open per warehouse. The sheet shows the expected on hand for each row and lets you enter the counted quantity, with a live variance. Save progress keeps the session across a refresh. Submit posts one adjustment per line whose counted number differs, with reason Count; a zero-variance submit still records that the count happened, and any row that would fall below reserved is skipped with a named error.",
            vi: "Bắt đầu kiểm kê từ màn hình Inventory; mỗi kho chỉ có một phiên kiểm kê mở. Bảng hiện tồn thực dự kiến của từng dòng và cho nhập số đếm thực tế, kèm chênh lệch trực tiếp. Lưu tiến độ giữ phiên qua lần tải lại. Gửi sẽ tạo một điều chỉnh cho mỗi dòng có số đếm khác, với lý do Kiểm kê; phiên không chênh lệch vẫn ghi nhận đã kiểm kê, và dòng nào sẽ xuống dưới mức đã giữ sẽ bị bỏ qua kèm lỗi nêu rõ."
          }
        }
      ]
    },
    {
      slug: "stock-statuses",
      question: {
        en: "What do In stock, Low, and Out mean?",
        vi: "Trạng thái Còn hàng, Thấp và Hết có ý nghĩa gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Out means available is zero or below. Low means available is at or below the row's reorder point. In stock means available is above the reorder point. The status uses available, not on hand, so a row with stock but many reservations can still be Low or Out. The filter counts use the same threshold expression as the rows, so the tab number and the visible rows agree.",
            vi: "Hết nghĩa là khả dụng bằng 0 hoặc thấp hơn. Thấp nghĩa là khả dụng bằng hoặc dưới điểm đặt hàng lại của dòng. Còn hàng nghĩa là khả dụng trên điểm đặt hàng lại. Trạng thái dùng khả dụng, không phải tồn thực, nên dòng còn hàng nhưng bị giữ nhiều vẫn có thể Thấp hoặc Hết. Số đếm trên bộ lọc dùng cùng biểu thức ngưỡng với các dòng, nên số trên tab và các dòng hiển thị khớp nhau."
          }
        }
      ]
    },
    {
      slug: "delete-stock-with-reservations",
      question: {
        en: "Why can’t I delete a stock row that has reservations?",
        vi: "Vì sao không thể xóa dòng tồn đang có lượng giữ?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "A stock row with pending reservations is referenced by an unpaid order or an active event hold; deleting it would leave that commitment without a source. Skycom therefore blocks the delete while pendings exist. Release or complete the related orders/events, or adjust the row only after the reservations clear. If the row is simply no longer used, set it inactive or archive it instead of deleting it.",
            vi: "Dòng tồn đang có lượng giữ được tham chiếu bởi một đơn chưa thanh toán hoặc một lượt giữ chỗ đang hoạt động; xóa đi sẽ để cam kết đó không còn nguồn. Vì vậy Skycom chặn xóa khi còn lượng giữ. Hãy giải phóng hoặc hoàn tất đơn/sự kiện liên quan, hoặc chỉ điều chỉnh dòng sau khi hết lượng giữ. Nếu dòng không còn dùng, hãy đặt ngừng hoạt động hoặc lưu trữ thay vì xóa."
          }
        }
      ]
    },
    {
      slug: "inventory-not-built",
      status: "planned",
      question: {
        en: "Why are BOM, zones, pallets, and RFID not available?",
        vi: "Vì sao chưa có BOM, khu vực, pallet và RFID?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Skycom deliberately models stock as quantity per product per warehouse, with a ledger-driven movement path. Bills of material, zone utilization, pallets, cartons, dock doors, and RFID would each add a different capacity or tracking model that the current inventory domain does not have. Rather than show invented percentages or fake rack numbers, the Inventory console shows only real rows, locations, and documents. These capabilities are tracked in the backlog and would be a separate inventory expansion, not a cosmetic toggle.",
            vi: "Skycom cố ý mô hình hóa tồn kho là số lượng theo sản phẩm và kho, với đường biến động dựa trên sổ kho. Định mức nguyên vật liệu (BOM), tỷ lệ sử dụng khu vực, pallet, thùng, cửa bốc xếp và RFID đều cần một mô hình công suất hoặc theo dõi khác mà miền tồn kho hiện tại chưa có. Thay vì hiện phần trăm bịa hoặc số kệ giả, màn hình Inventory chỉ hiện dòng, vị trí và chứng từ thật. Các khả năng này đang được ghi trong backlog và sẽ là một mở rộng tồn kho riêng, không phải một nút bật/tắt."
          }
        }
      ]
    }
  ]
}
