export default {
  key: "customization_payment_methods",
  icon: "tune",
  title: {
    en: "Customization & payment methods",
    vi: "Tùy chỉnh & phương thức thanh toán"
  },
  questions: [
    {
      slug: "categories-properties-tables",
      question: {
        en: "How do categories, dynamic properties, and dynamic tables work together?",
        vi: "Danh mục, thuộc tính động và bảng động phối hợp thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "One category owns three related pieces: the record's classification, its property mapping (what the extra fields mean), and its table configuration (which columns and filters the list shows). A record is created under a category, so its fields and list layout follow that category. The index opens on the first category for the resource unless you switch, which is why the first category should have data. These three pieces are edited on Categories, Dynamic Properties, and Dynamic Tables, not on the record form.",
            vi: "Một danh mục sở hữu ba phần liên quan: phân loại bản ghi, ánh xạ thuộc tính (trường phụ có ý nghĩa gì) và cấu hình bảng (cột và bộ lọc danh sách hiển thị). Bản ghi được tạo dưới một danh mục, nên trường và bố cục danh sách theo danh mục đó. Danh sách mở ở danh mục đầu tiên của tài nguyên trừ khi bạn chuyển, vì vậy danh mục đầu tiên nên có dữ liệu. Ba phần này được sửa ở Danh mục, Thuộc tính động và Bảng động, không phải trên biểu mẫu bản ghi."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Categories", vi: "Mở Danh mục" }, path: "company_categories_path" },
            { label: { en: "Open Dynamic Properties", vi: "Mở Thuộc tính động" }, path: "company_property_mappings_path" },
            { label: { en: "Open Dynamic Tables", vi: "Mở Bảng động" }, path: "company_table_configs_path" }
          ]
        }
      ]
    },
    {
      slug: "property-types-and-slots",
      question: {
        en: "What field types can I add, and how many?",
        vi: "Có thể thêm những loại trường nào và bao nhiêu?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "You can map five types: text, whole number, decimal (up to four decimal places), yes/no, and date and time. Skycom assigns the field automatically; you choose the label and type, not a column name. The available fields per type are finite and shared by the resource, so a category can only use the fields that exist. Blank values are allowed, and the type rule is enforced on save; custom validation rules are not supported.",
            vi: "Bạn có thể ánh xạ năm loại: văn bản, số nguyên, số thập phân (tối đa bốn chữ số thập phân), có/không, và ngày giờ. Skycom tự gán trường; bạn chọn nhãn và kiểu, không chọn tên cột. Số trường khả dụng theo từng kiểu có giới hạn và dùng chung cho tài nguyên, nên một danh mục chỉ dùng được các trường đang có. Giá trị trống được phép, quy tắc kiểu được kiểm tra khi lưu; không hỗ trợ quy tắc kiểm tra tùy chỉnh."
          }
        }
      ]
    },
    {
      slug: "columns-order-filters",
      question: {
        en: "How do I hide, reorder, or filter columns?",
        vi: "Làm sao ẩn, sắp xếp lại hoặc lọc cột?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Open Dynamic Tables, choose the category, and edit its table configuration. Each column can be visible or hidden, has an order, and can opt into search or a filter; a filter can be a range or a set of buckets for numbers and dates. The record form still shows the fields for that category, so hiding a column only changes the list, not the stored value. The first column is typically the record name and should stay visible.",
            vi: "Mở Bảng động, chọn danh mục và sửa cấu hình bảng. Mỗi cột có thể hiện hoặc ẩn, có thứ tự, và có thể bật tìm kiếm hoặc bộ lọc; bộ lọc có thể là khoảng hoặc các nhóm cho số và ngày. Biểu mẫu bản ghi vẫn hiện trường của danh mục đó, nên ẩn cột chỉ đổi danh sách, không đổi giá trị đã lưu. Cột đầu thường là tên bản ghi và nên giữ hiển thị."
          }
        }
      ]
    },
    {
      slug: "table-config-logs",
      question: {
        en: "What are table config logs for?",
        vi: "Nhật ký cấu hình bảng dùng để làm gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Table Config Logs record changes to a table configuration: who changed it, when, and what changed. Use them when a column disappears, a filter behaves differently, or two administrators disagree about the layout. The log is an audit trail, not an undo button; to restore a layout, edit the table configuration back to the intended columns. Similar logs exist for attendance, event, and workflow configuration changes.",
            vi: "Nhật ký cấu hình bảng ghi lại thay đổi của một cấu hình bảng: ai đổi, khi nào và đổi gì. Dùng khi một cột biến mất, bộ lọc chạy khác hoặc hai quản trị viên không thống nhất về bố cục. Nhật ký là dấu vết kiểm tra, không phải nút hoàn tác; muốn khôi phục bố cục, hãy sửa cấu hình bảng về các cột mong muốn. Các nhật ký tương tự tồn tại cho thay đổi cấu hình chấm công, sự kiện và quy trình."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Table Config Logs", vi: "Mở Nhật ký cấu hình bảng" }, path: "company_table_config_logs_path" }
          ]
        }
      ]
    },
    {
      slug: "company-versus-branch-payment-methods",
      question: {
        en: "How do company-level and branch-level payment methods differ?",
        vi: "Phương thức thanh toán cấp công ty và cấp chi nhánh khác nhau thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "The payment method catalog is global, but a link connects a method to your company or one branch. Company-level links are the defaults and the only ones listed on the Payments dashboard. Branch links are copied from active company methods when the branch is created and can hold their own merchant account details, so different branches can collect into different bank accounts. A branch method stays inactive until the company-level method is active.",
            vi: "Danh mục phương thức thanh toán là toàn cầu, nhưng một liên kết nối phương thức với công ty hoặc một chi nhánh. Liên kết cấp công ty là mặc định và là loại duy nhất hiện trên bảng Thanh toán. Liên kết cấp chi nhánh được sao từ các phương thức công ty đang hoạt động khi tạo chi nhánh và có thể giữ thông tin tài khoản merchant riêng, nên các chi nhánh có thể thu vào tài khoản ngân hàng khác nhau. Phương thức chi nhánh vẫn tắt cho đến khi phương thức cấp công ty hoạt động."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Payment Methods", vi: "Mở Phương thức thanh toán" }, path: "company_payment_method_appointments_path" }
          ]
        }
      ]
    },
    {
      slug: "branch-payment-activation",
      question: {
        en: "Why can’t I activate a branch payment method, and do branch methods follow later company changes?",
        vi: "Vì sao không bật được phương thức chi nhánh và phương thức chi nhánh có theo thay đổi công ty sau này không?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "A branch method can only be active while the same method is active at the company level; the toggle is disabled with an “enable at company level first” hint. Disabling a method at company level cascades the lifecycle status to every branch. Other changes do not cascade: branch links are copied when the branch is created, so a method activated later for the company does not automatically appear on existing branches; create it for those branches explicitly.",
            vi: "Phương thức chi nhánh chỉ hoạt động được khi cùng phương thức đó đang hoạt động ở cấp công ty; nút bật bị vô hiệu kèm gợi ý “bật ở cấp công ty trước”. Tắt một phương thức ở cấp công ty sẽ lan trạng thái vòng đời xuống mọi chi nhánh. Các thay đổi khác không lan: liên kết chi nhánh được sao khi tạo chi nhánh, nên phương thức bật sau đó cho công ty không tự xuất hiện ở chi nhánh cũ; hãy tạo riêng cho các chi nhánh đó."
          }
        }
      ]
    },
    {
      slug: "customize-sidebar",
      question: {
        en: "How do I customize the sidebar with quick links?",
        vi: "Làm sao tùy chỉnh thanh bên bằng liên kết nhanh?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Open Settings → Quick Links. The editor lets the owner create custom groups and items with a name and a URL; custom groups render above the built-in sidebar for the whole company. Use an in-app path such as a filtered order list or a dashboard, not an external script. Saving refreshes the browser data and reloads the sidebar; only the owner can update this configuration.",
            vi: "Mở Settings → Quick Links. Trình sửa cho chủ sở hữu tạo nhóm và mục tùy chỉnh với tên và URL; nhóm tùy chỉnh hiện phía trên thanh bên mặc định cho cả công ty. Dùng đường dẫn trong ứng dụng như danh sách đơn đã lọc hoặc bảng điều khiển, không dùng script bên ngoài. Lưu sẽ làm mới dữ liệu trình duyệt và tải lại thanh bên; chỉ chủ sở hữu cập nhật được cấu hình này."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Quick Links", vi: "Mở Liên kết nhanh" }, path: "company_settings_path" }
          ]
        }
      ]
    }
  ]
}
