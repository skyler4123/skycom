export default {
  key: "catalog_customers",
  icon: "inventory_2",
  title: {
    en: "Catalog, categories & customers",
    vi: "Danh mục, danh mục phân loại & khách hàng"
  },
  questions: [
    {
      slug: "product-versus-service",
      question: {
        en: "What is the difference between a product and a service?",
        vi: "Sự khác nhau giữa sản phẩm và dịch vụ là gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "A product is a physical or stocked item: it has stock rows per warehouse, can be received, transferred, adjusted, and consumed by a sale. A service is work you sell without a stock ledger: a consultation, treatment, repair, or rental, priced in the catalog and sold through POS or a booking. Both can be searched, categorized, and given dynamic properties, but only products appear in the warehouse ledger and stock counts.",
            vi: "Sản phẩm là mặt hàng vật lý hoặc có tồn kho: có dòng tồn theo từng kho, có thể nhập, chuyển, điều chỉnh và bị trừ khi bán. Dịch vụ là công việc bán không có sổ kho: tư vấn, điều trị, sửa chữa hoặc cho thuê, được định giá trong danh mục và bán qua POS hoặc lịch đặt. Cả hai đều có thể tìm kiếm, phân loại và gắn thuộc tính động, nhưng chỉ sản phẩm xuất hiện trong sổ kho và số lượng tồn."
          }
        }
      ]
    },
    {
      slug: "price-versus-cost",
      question: {
        en: "How do price and cost affect sales and margin reports?",
        vi: "Giá bán và giá vốn ảnh hưởng đến báo cáo bán hàng và lợi nhuận thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Price is what the customer pays; it is stored on the product or service and used by POS and order lines. Cost is what the item costs you; it is optional, but it is the input for gross profit, margin, and cost coverage in Dashboard and Analytics. When costs are missing, margin is shown as blank rather than zero, and the cost-coverage indicator explains how much of the revenue has known cost. Filling costs for your best-selling items gives the most useful margin picture first.",
            vi: "Giá bán là số tiền khách trả; giá này lưu trên sản phẩm hoặc dịch vụ và được POS cùng các dòng đơn hàng dùng. Giá vốn là chi phí bạn bỏ ra; không bắt buộc, nhưng là đầu vào cho lợi nhuận gộp, biên lợi nhuận và độ phủ giá vốn trên Bảng điều khiển và Phân tích. Khi thiếu giá vốn, biên lợi nhuận hiển thị trống thay vì 0, và chỉ báo độ phủ giá vốn cho biết bao nhiêu phần doanh thu đã có giá vốn. Nhập giá vốn cho các mặt hàng bán chạy trước sẽ cho bức tranh lợi nhuận hữu ích nhất."
          }
        }
      ]
    },
    {
      slug: "what-is-a-category",
      question: {
        en: "What is a category, and why does every record need one?",
        vi: "Danh mục phân loại là gì và vì sao mọi bản ghi đều cần một danh mục?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "A category is a node that classifies records of one resource: products, services, customers, employees, branches, and others. It owns two things that make the record usable: the dynamic property mapping (which extra fields mean what) and the table configuration (which columns and filters the list shows). A record without a category would have no defined extra fields and no list layout, so Skycom requires one. The same category cannot be reused across different resources.",
            vi: "Danh mục phân loại là một nút phân loại bản ghi của một tài nguyên: sản phẩm, dịch vụ, khách hàng, nhân viên, chi nhánh và các tài nguyên khác. Danh mục sở hữu hai thứ giúp bản ghi dùng được: ánh xạ thuộc tính động (trường phụ nào có ý nghĩa gì) và cấu hình bảng (cột và bộ lọc nào hiển thị). Bản ghi không có danh mục sẽ không có trường phụ được định nghĩa và không có bố cục danh sách, nên Skycom bắt buộc phải có. Không thể dùng lại cùng một danh mục cho tài nguyên khác."
          }
        }
      ]
    },
    {
      slug: "dynamic-properties",
      question: {
        en: "How do dynamic properties let me add my own fields?",
        vi: "Thuộc tính động giúp tôi thêm trường riêng như thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Each category has a property mapping: a list of typed extra fields. You choose the meaning and the type — text, whole number, decimal, yes/no, or date and time — and Skycom assigns the field automatically. Two categories of the same resource can therefore show different fields without a database change. The available fields are finite, and blank values are allowed; the type rule is enforced on save.",
            vi: "Mỗi danh mục có một ánh xạ thuộc tính: danh sách các trường phụ có kiểu dữ liệu. Bạn chọn ý nghĩa và kiểu — văn bản, số nguyên, số thập phân, có/không, hoặc ngày giờ — và Skycom tự gán trường. Vì vậy hai danh mục của cùng một tài nguyên có thể hiển thị trường khác nhau mà không cần đổi cơ sở dữ liệu. Số trường khả dụng có giới hạn, giá trị trống được phép, và quy tắc kiểu dữ liệu được kiểm tra khi lưu."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Dynamic Properties", vi: "Mở Thuộc tính động" }, path: "company_property_mappings_path" }
          ]
        }
      ]
    },
    {
      slug: "columns-and-filters",
      question: {
        en: "How do I choose the columns and filters in a list?",
        vi: "Làm sao chọn cột và bộ lọc trong một danh sách?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "The list layout is owned by the category's table configuration. Open Dynamic Tables, choose the category and resource, then set which standard and dynamic columns are visible, their order, and which columns can be searched or filtered. The index page always opens on the first category unless you switch it, so make sure that first category has data and a useful layout. Table Config Logs keep a history of changes if a column disappears unexpectedly.",
            vi: "Bố cục danh sách do cấu hình bảng của danh mục quyết định. Mở Bảng động, chọn danh mục và tài nguyên, sau đó đặt cột chuẩn và cột động nào hiển thị, thứ tự, và cột nào được tìm kiếm hoặc lọc. Trang danh sách luôn mở ở danh mục đầu tiên trừ khi bạn chuyển, nên hãy bảo đảm danh mục đầu tiên có dữ liệu và bố cục hữu ích. Nhật ký cấu hình bảng lưu lịch sử thay đổi nếu một cột biến mất bất ngờ."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Dynamic Tables", vi: "Mở Bảng động" }, path: "company_table_configs_path" },
            { label: { en: "Open Table Config Logs", vi: "Mở Nhật ký cấu hình bảng" }, path: "company_table_config_logs_path" }
          ]
        }
      ]
    },
    {
      slug: "inactive-archived-deleted",
      question: {
        en: "What is the difference between inactive, archived, and deleted?",
        vi: "Sự khác nhau giữa ngừng hoạt động, lưu trữ và đã xóa là gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Inactive means the record still exists but should not be used in new work; it stays visible where history needs it. Archived means the record is kept for reference and is normally out of the active lists. Deleted is a soft delete: the record is hidden from normal views, but its history and links are retained for audit. None of these is a hard database delete, so a deleted product or customer can still appear on an old order or invoice. Use the lifecycle status that matches the intent, not the most dramatic one.",
            vi: "Ngừng hoạt động nghĩa là bản ghi vẫn tồn tại nhưng không nên dùng cho công việc mới; nó vẫn hiện ở nơi cần lịch sử. Lưu trữ nghĩa là bản ghi được giữ để tham chiếu và thường ra khỏi danh sách đang hoạt động. Đã xóa là xóa mềm: bản ghi bị ẩn khỏi chế độ xem thông thường nhưng lịch sử và liên kết vẫn được giữ để kiểm tra. Không có thao tác xóa cứng cơ sở dữ liệu, nên sản phẩm hoặc khách hàng đã xóa vẫn có thể xuất hiện trên đơn hàng hay hóa đơn cũ. Hãy dùng trạng thái vòng đời đúng với ý định, không phải trạng thái mạnh nhất."
          }
        }
      ]
    },
    {
      slug: "customer-versus-user",
      question: {
        en: "What is a customer, and when does it need a User login?",
        vi: "Khách hàng là gì và khi nào cần tài khoản đăng nhập?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "A customer is the person or organisation you sell to; it belongs to your company and anchors orders, invoices, bookings, and visit records. Most customers never need a login: a walk-in can be created at POS with just a name, and a cashier can sell without attaching anyone. Link a customer to a User only when that person must sign in to a customer-facing surface or when your process needs the login identity. A customer without a login is still a full customer for reporting and history.",
            vi: "Khách hàng là cá nhân hoặc tổ chức bạn bán cho; khách hàng thuộc công ty bạn và là điểm neo cho đơn hàng, hóa đơn, lượt đặt và hồ sơ khách đến. Hầu hết khách hàng không cần đăng nhập: khách tại quầy có thể được tạo ở POS chỉ với tên, và thu ngân có thể bán mà không gắn khách. Chỉ liên kết khách hàng với User khi người đó cần đăng nhập vào bề mặt dành cho khách hoặc khi quy trình cần danh tính đăng nhập. Khách hàng không có đăng nhập vẫn là khách hàng đầy đủ cho báo cáo và lịch sử."
          }
        }
      ]
    },
    {
      slug: "customer-profiles",
      question: {
        en: "What are customer profiles and subprofiles?",
        vi: "Hồ sơ khách hàng và hồ sơ phụ là gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Profiles and subprofiles are extension buckets for per-domain customer details that should not bloat the base customer record. A profile belongs to one customer, and a subprofile belongs to one profile; both are full dynamic resources with their own categories, custom fields, table layouts, and search. Use them for things like a second persona, a household member, a check-up history, or a site-specific detail. They are not duplicates of the customer and do not replace the customer's core name, contact, or order history.",
            vi: "Hồ sơ và hồ sơ phụ là các nhóm mở rộng cho thông tin khách hàng theo từng lĩnh vực, để không làm phình bản ghi khách hàng gốc. Hồ sơ thuộc một khách hàng, hồ sơ phụ thuộc một hồ sơ; cả hai là tài nguyên động đầy đủ với danh mục, trường tùy chỉnh, bố cục bảng và tìm kiếm riêng. Dùng chúng cho các trường hợp như danh tính thứ hai, thành viên hộ gia đình, lịch sử khám hoặc chi tiết theo địa điểm. Chúng không phải bản sao của khách hàng và không thay thế tên, liên hệ hay lịch sử đơn hàng cốt lõi."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Customer Profiles", vi: "Mở Hồ sơ khách hàng" }, path: "company_customer_profiles_path" },
            { label: { en: "Open Customer Subprofiles", vi: "Mở Hồ sơ phụ khách hàng" }, path: "company_customer_subprofiles_path" }
          ]
        }
      ]
    }
  ]
}
