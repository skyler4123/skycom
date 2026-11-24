export default {
  key: "notifications_documents_storage",
  icon: "notifications",
  title: {
    en: "Notifications, documents & storage",
    vi: "Thông báo, tài liệu & lưu trữ"
  },
  questions: [
    {
      slug: "who-creates-notifications",
      question: {
        en: "What are notifications, and who creates them?",
        vi: "Thông báo là gì và ai tạo?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Notifications are in-app messages: an operational alert, a system event, or a direct message to one employee. In v1 they are created by Skycom services and background jobs, not composed by a person in a form. Each notification can target a tag audience or one direct recipient, and the bell shows the unread count in real time. The inbox only shows what the employee is subscribed to or directly addressed.",
            vi: "Thông báo là tin nhắn trong ứng dụng: cảnh báo vận hành, sự kiện hệ thống hoặc tin nhắn trực tiếp cho một nhân viên. Trong v1, chúng do các dịch vụ và tiến trình nền của Skycom tạo, không do người dùng soạn trong biểu mẫu. Mỗi thông báo có thể nhắm theo thẻ hoặc một người nhận trực tiếp, và chuông hiện số chưa đọc theo thời gian thực. Hộp thư chỉ hiện thông báo mà nhân viên đã đăng ký hoặc được gửi trực tiếp."
          }
        }
      ]
    },
    {
      slug: "notification-tags-subscriptions",
      question: {
        en: "What are notification tags and subscriptions?",
        vi: "Thẻ thông báo và đăng ký nhận là gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "A notification tag is a topic such as Imports, Attendance, or a specific operation. A tag appointment attaches a notification to that topic, and an employee's subscription decides whether the tag's messages appear in their inbox. Direct-recipient notifications bypass tags and always reach the named employee. Use tags for broadcasts and direct recipients for one-person alerts such as a host or parcel notice.",
            vi: "Thẻ thông báo là một chủ đề như Nhập dữ liệu, Chấm công hoặc một vận hành cụ thể. Liên kết thẻ gắn thông báo vào chủ đề, và đăng ký của nhân viên quyết định thông báo của thẻ có hiện trong hộp thư hay không. Thông báo gửi trực tiếp bỏ qua thẻ và luôn đến đúng người. Dùng thẻ cho tin phát chung và người nhận trực tiếp cho cảnh báo một người như lễ tân hoặc bưu phẩm."
          }
        }
      ]
    },
    {
      slug: "mark-notifications-read",
      question: {
        en: "How do I mark notifications read?",
        vi: "Làm sao đánh dấu thông báo đã đọc?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Open a notification and it is marked read for you; the inbox also offers Mark all read. Read state is stored per employee, so one person reading a broadcast does not mark it read for everyone. The bell badge is the unread count for your subscriptions and direct messages, and it refreshes on navigation and through the notification socket. There is no email or mobile push copy of the same message.",
            vi: "Mở một thông báo sẽ đánh dấu đã đọc cho bạn; hộp thư cũng có Đánh dấu tất cả đã đọc. Trạng thái đã đọc lưu theo từng nhân viên, nên một người đọc tin phát chung không đánh dấu thay cho mọi người. Huy hiệu chuông là số chưa đọc của các đăng ký và tin trực tiếp, được làm mới khi chuyển trang và qua socket thông báo. Không có bản email hay push di động của cùng tin nhắn."
          }
        }
      ]
    },
    {
      slug: "documents-and-delivery",
      question: {
        en: "What is a Document, and how does it reach employees?",
        vi: "Tài liệu là gì và đến tay nhân viên thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "A Document is a company-scoped policy, guide, notice, or announcement with a markdown body and optional attachments. You assign it to employees through document-employee appointments, so the same document appears in their document list. A published announcement also appears on the mobile Home as the latest company notice. Documents do not send email; the employee sees them in the app.",
            vi: "Tài liệu là chính sách, hướng dẫn, thông báo hoặc tin nội bộ của công ty với nội dung markdown và tệp đính kèm tùy chọn. Bạn gán tài liệu cho nhân viên qua liên kết tài liệu-nhân viên, nên cùng tài liệu xuất hiện trong danh sách của họ. Thông báo đã xuất bản cũng xuất hiện trên Home di động như tin công ty mới nhất. Tài liệu không gửi email; nhân viên xem trong ứng dụng."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Documents", vi: "Mở Tài liệu" }, path: "company_documents_path" }
          ]
        }
      ]
    },
    {
      slug: "document-statuses",
      question: {
        en: "What do document draft/published/archived mean?",
        vi: "Trạng thái nháp/đã xuất bản/lưu trữ của tài liệu có ý nghĩa gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Draft is work in progress and is not the default view for employees. Published is visible to the assigned employees and can surface on mobile as an announcement. Archived is kept for history but removed from the active reading list. The documents index defaults to published unless you choose another status, so an unpublished draft can look missing until you change the filter.",
            vi: "Nháp là bản đang làm và không phải chế độ xem mặc định cho nhân viên. Đã xuất bản là hiển thị cho nhân viên được gán và có thể hiện trên di động như thông báo. Lưu trữ là giữ để tra cứu nhưng bỏ khỏi danh sách đọc đang hoạt động. Danh sách tài liệu mặc định lọc đã xuất bản trừ khi bạn chọn trạng thái khác, nên bản nháp chưa xuất bản có thể trông như bị thiếu cho đến khi đổi bộ lọc."
          }
        }
      ]
    },
    {
      slug: "folders-and-files",
      question: {
        en: "What are Folders and StoredFiles?",
        vi: "Thư mục và Tệp lưu trữ là gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Folders are company-wide containers, and a root folder acts like a bucket; files live inside a folder, never at the root. A stored file keeps the file, its size, extension, file type, and an optional link to a record such as an invoice or purchase. You can upload, download, and delete files with the normal folder permissions. Folder names are unique within the same parent, and a folder cannot be deleted while it contains files or child folders.",
            vi: "Thư mục là vùng chứa trong công ty, và thư mục gốc hoạt động như một bucket; tệp nằm trong thư mục, không bao giờ ở gốc. Tệp lưu trữ giữ tệp, kích thước, phần mở rộng, loại tệp và liên kết tùy chọn đến bản ghi như hóa đơn hoặc đơn mua. Bạn có thể tải lên, tải xuống và xóa tệp theo quyền thư mục thông thường. Tên thư mục là duy nhất trong cùng thư mục cha, và không thể xóa thư mục khi còn tệp hoặc thư mục con."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Folders", vi: "Mở Thư mục" }, path: "company_folders_path" }
          ]
        }
      ]
    },
    {
      slug: "file-types-and-limits",
      question: {
        en: "Which file types and sizes are allowed, and why can’t I delete a folder?",
        vi: "Cho phép những loại và kích thước tệp nào, và vì sao không xóa được thư mục?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Images can be up to 10 MB; PDFs and Office files up to 20 MB; text and CSV up to 5 MB; archives up to 50 MB. The file type must be on the allowlist, so renaming an unsupported file does not make it uploadable. A folder with any file or child folder is protected from deletion to keep the storage audit honest; empty it first, then delete it. Deleting a file removes its stored data in the background.",
            vi: "Ảnh tối đa 10 MB; PDF và tệp Office tối đa 20 MB; văn bản và CSV tối đa 5 MB; tệp nén tối đa 50 MB. Loại tệp phải nằm trong danh sách cho phép, nên đổi tên tệp không được hỗ trợ sẽ không làm tệp tải lên được. Thư mục còn tệp hoặc thư mục con được bảo vệ khỏi xóa để giữ kiểm tra lưu trữ trung thực; hãy làm trống trước rồi xóa. Xóa tệp sẽ gỡ dữ liệu đã lưu trong nền."
          }
        }
      ]
    },
    {
      slug: "storage-billing",
      status: "planned",
      question: {
        en: "Is storage billed or quota-limited?",
        vi: "Lưu trữ có bị tính phí hoặc giới hạn hạn mức không?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Not yet. Storage has per-file size limits and a type allowlist, but no company quota, no versioning, and no credit deduction for stored bytes. The storage statistics page shows total size, files, folders, and a by-type breakdown, and its numbers are kept for an hour, so it can lag after an upload. Metering and billing storage is tracked as a future capability; the size and file-type records already exist to support it.",
            vi: "Chưa có. Lưu trữ có giới hạn kích thước từng tệp và danh sách loại cho phép, nhưng chưa có hạn mức công ty, chưa có phiên bản và chưa trừ tín dụng theo dung lượng. Trang thống kê lưu trữ hiện tổng dung lượng, số tệp, số thư mục và phân bổ theo loại; số liệu được giữ một giờ nên có thể chậm sau khi tải lên. Đo và tính phí lưu trữ đang được ghi là khả năng tương lai; dữ liệu kích thước và loại tệp đã có sẵn để hỗ trợ."
          }
        }
      ]
    }
  ]
}
