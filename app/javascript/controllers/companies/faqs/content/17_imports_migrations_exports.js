export default {
  key: "imports_migrations_exports",
  icon: "upload_file",
  title: {
    en: "Imports, migrations & exports",
    vi: "Nhập dữ liệu, chuyển dữ liệu & xuất dữ liệu"
  },
  questions: [
    {
      slug: "import-versus-migration",
      question: {
        en: "What is the difference between Import and Data Migration?",
        vi: "Nhập dữ liệu và Chuyển dữ liệu khác nhau thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Import is the owner's everyday CSV loader for one master table at a time, with one category, one file, a full-file dry run, and a log-based rollback. Data Migration is the config-driven loader for a larger move: it can ingest several related tables in a defined order, accepts chunked uploads, and has its own dry run, approval, resume, and rollback. Use Import for a product or customer list; use Data Migration when the data spans tables or needs a repeatable migration configuration.",
            vi: "Nhập dữ liệu là công cụ CSV hằng ngày cho chủ sở hữu, mỗi lần một bảng chính, với một danh mục, một tệp, chạy thử toàn bộ tệp và hoàn tác dựa trên nhật ký. Chuyển dữ liệu là công cụ nhập theo cấu hình cho lần chuyển lớn hơn: có thể nhập nhiều bảng liên quan theo thứ tự định nghĩa, nhận tệp tải lên theo phần, và có chạy thử, duyệt, tiếp tục và hoàn tác riêng. Dùng Nhập dữ liệu cho danh sách sản phẩm hoặc khách hàng; dùng Chuyển dữ liệu khi dữ liệu trải nhiều bảng hoặc cần cấu hình chuyển lặp lại."
          }
        }
      ]
    },
    {
      slug: "importable-tables",
      question: {
        en: "Which tables can I import into?",
        vi: "Có thể nhập vào những bảng nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Import only accepts master and reference tables: branches, brands, customer profiles and subprofiles, customers, departments, employee profiles and subprofiles, employees, facilities, products, services, suppliers, and warehouses. It deliberately excludes users, roles, policies, permission logs, platform configuration, orders, invoices, payments, credits, stock movements, documents, and money-bearing memberships. The picker and the backend share the same allowlist, and the backend re-validates every submitted table name.",
            vi: "Nhập dữ liệu chỉ nhận bảng chính và tham chiếu: chi nhánh, thương hiệu, hồ sơ và hồ sơ phụ khách hàng, khách hàng, phòng ban, hồ sơ và hồ sơ phụ nhân viên, nhân viên, cơ sở vật chất, sản phẩm, dịch vụ, nhà cung cấp và kho. Công cụ cố ý loại trừ người dùng, vai trò, chính sách, nhật ký quyền, cấu hình nền tảng, đơn hàng, hóa đơn, thanh toán, tín dụng, biến động tồn, tài liệu và membership có tiền. Bộ chọn và backend dùng chung danh sách cho phép, và backend kiểm tra lại mọi tên bảng được gửi."
          }
        }
      ]
    },
    {
      slug: "csv-header-contract",
      question: {
        en: "What must the CSV header look like?",
        vi: "Header CSV phải trông như thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Each header must be an exact table field name, such as name, email, price_cents, or a category property display name, such as Skin Type Suitability. Headers are case-sensitive after trimming, a leading byte-order mark is ignored, and raw slot names such as property_string_1 are rejected. Duplicate, empty, and unknown headers fail with the full expected list. System-owned columns such as id, company_id, metadata, and timestamps are excluded; price_cents is the raw amount in the smallest currency unit.",
            vi: "Mỗi header phải là tên trường chính xác của bảng, như name, email, price_cents, hoặc tên hiển thị của thuộc tính danh mục, như Phù hợp loại da. Header phân biệt hoa thường sau khi cắt khoảng trắng, dấu byte-order đầu tệp được bỏ qua, và tên ô thô như property_string_1 bị từ chối. Header trùng, rỗng hoặc không biết sẽ báo lỗi kèm danh sách đầy đủ mong đợi. Các cột do hệ thống sở hữu như id, company_id, metadata và mốc thời gian bị loại; price_cents là số tiền thô theo đơn vị tiền tệ nhỏ nhất."
          }
        }
      ]
    },
    {
      slug: "import-dry-run-approve",
      question: {
        en: "How do dry run, approval, and rollback work?",
        vi: "Chạy thử, duyệt và hoàn tác hoạt động thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Upload the file, choose the target table and category, and run the dry run; Skycom validates the whole file at once and stores the header snapshot, file fingerprints, and row errors. Approval is allowed only when the last dry run passed and still matches the current category fields and the uploaded file. The import then writes the rows in batches, and rollback replays its log to remove what that run created. A failed run is terminal: roll it back and create a new import rather than retrying the same one.",
            vi: "Tải tệp lên, chọn bảng đích và danh mục, rồi chạy thử; Skycom kiểm tra toàn bộ tệp một lần và lưu ảnh chụp header, dấu nhận diện tệp và lỗi từng dòng. Chỉ được duyệt khi lần chạy thử cuối đã đạt và vẫn khớp trường của danh mục hiện tại cùng tệp đã tải. Việc nhập sau đó ghi từng lô, và hoàn tác phát lại nhật ký để xóa những gì lần đó tạo. Lần chạy lỗi là trạng thái cuối: hãy hoàn tác rồi tạo lần nhập mới thay vì thử lại cùng lần."
          }
        }
      ]
    },
    {
      slug: "migrate-related-data",
      question: {
        en: "How do I migrate related data across several tables?",
        vi: "Làm sao chuyển dữ liệu liên quan qua nhiều bảng?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Use Data Migration, not Import. A migration config declares the target tables and the order they load, the source columns, the category/property mapping, and the safe-target rules for each table. Upload the CSV parts, run the dry run, review the counts and error samples, then approve; the job processes batches, updates progress, and sends notifications. The same run can be rolled back from its log if the import must be undone.",
            vi: "Dùng Chuyển dữ liệu, không dùng Nhập dữ liệu. Cấu hình chuyển khai báo các bảng đích và thứ tự nạp, cột nguồn, ánh xạ danh mục/thuộc tính và quy tắc đích an toàn cho từng bảng. Tải các phần CSV lên, chạy thử, xem số lượng và mẫu lỗi, rồi duyệt; job xử lý theo lô, cập nhật tiến độ và gửi thông báo. Cùng lần chạy có thể hoàn tác từ nhật ký nếu cần hủy việc nhập."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Migrations", vi: "Mở Chuyển dữ liệu" }, path: "company_company_migrations_path" }
          ]
        }
      ]
    },
    {
      slug: "export-csv",
      question: {
        en: "How do I export a list to CSV, and why is Export missing on some pages?",
        vi: "Làm sao xuất danh sách ra CSV và vì sao một số trang thiếu nút Xuất?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "On an enabled index page, use Export in the header; Skycom downloads the full filtered set as CSV, not only the visible page. The button is controlled by a Skycom-level allowlist, so it appears only on pages the platform has enabled, and a disabled page rejects an export request with an error. The Inventory console has its own export of the current ledger search and filter. Exports are capped by a maximum record count, and a larger request is rejected rather than truncated.",
            vi: "Trên trang danh sách được bật, dùng Xuất ở đầu trang; Skycom tải toàn bộ tập đã lọc dưới dạng CSV, không chỉ trang đang thấy. Nút này do danh sách cho phép cấp nền tảng quyết định, nên chỉ hiện ở trang được bật, và trang bị tắt sẽ từ chối yêu cầu xuất kèm lỗi. Màn hình Inventory có bản xuất riêng của tìm kiếm và bộ lọc sổ kho hiện tại. Việc xuất bị giới hạn số bản ghi tối đa; yêu cầu lớn hơn sẽ bị từ chối thay vì cắt bớt."
          }
        }
      ]
    },
    {
      slug: "export-limit",
      question: {
        en: "Are exports limited?",
        vi: "Việc xuất dữ liệu có bị giới hạn không?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Yes. A generic index export stops at the configured maximum record count and returns an error when the filtered set is larger; narrow the filters or export in smaller periods. The Inventory ledger export is a console-specific file and is not governed by the page allowlist, but it still builds from the current search and filter. Exports are generated from the same records the page shows, so a permission-hidden column or record is not included.",
            vi: "Có. Bản xuất danh sách chung dừng ở số bản ghi tối đa đã cấu hình và trả lỗi khi tập đã lọc lớn hơn; hãy thu hẹp bộ lọc hoặc xuất theo giai đoạn nhỏ hơn. Bản xuất sổ kho của Inventory là tệp riêng của màn hình, không theo danh sách cho phép của trang, nhưng vẫn dựng từ tìm kiếm và bộ lọc hiện tại. Bản xuất lấy từ đúng các bản ghi trang hiển thị, nên cột hoặc bản ghi bị ẩn do quyền sẽ không được đưa vào."
          }
        }
      ]
    }
  ]
}
