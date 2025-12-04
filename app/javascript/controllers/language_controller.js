// Require a global dictionary object named "LanguageDictionary", so we can override it if needed in other Stimulus controllers
// Expect element have attribute for initialize targets "word": data-language-key="value"
// Ex: data-language-key="hello" will be inserted "Hello" text in English language by a dictionary object based on pathname
// This Stimulus controller also listen to change event of languageCodeValue to update all targets' text content
// This Stimulus controller require targets contain only text content, not HTML content
// Use methods from "this" from ApplicationController
//   translate(key)
//   triggerLanguageDropdown()
//   languageCodeTextTarget()

import ApplicationController from "controllers/application_controller";
import { Cookie, setCookie, openPopover, closeSwal } from "controllers/helpers";

export default class LanguageController extends ApplicationController {
  static targets = ["codeText", "word", "triggerDropdown"];
  static values = {
    languageCode: { type: String },
  }

  initialize() {
    // Initialize dictionary early because updateTranslations need it, so the another controller can override it before connect
    this.initDictionary();

    setTimeout(() => {
      this.initValues();
      this.initTargets();
      this.initActions();
    }, 200);
  }

  initDictionary() {
    window.LanguageDictionary = this.dictionary();
  }

  // Get languageCode from Cookie > default to "en"
  initValues() {
    this.languageCodeValue = Cookie('languageCode') || "en";
  }

  initTargets() {
    this.element.querySelectorAll("[data-language-key]").forEach((element) => {
      element.setAttribute(`data-${this.identifier}-target`, "word");
    });

    // trigger dropdown target already added by another controller
  }

  initActions() {
    // Add action to dropdown to change language code value
    if (this.hasTriggerDropdownTarget) {
      this.triggerDropdownTarget.setAttribute(
        `data-action`,
        `click->${this.identifier}#openDropdown`
      );
    }
  }

  openDropdown(event) {
    // No need to implement anything here, just to have action to open dropdown
    event.preventDefault();
    console.log("Dropdown clicked");
    console.log(event.params)
    openPopover({
      parentElement: event.currentTarget,
      html: this.languageDropdownHTML(),
      position: "bottom-right",
      className: "w-fit! -translate-x-full p-0!",
    })
  }

  // changeLanguage(event) {
  //   console.log("Change language clicked");
  //   console.log(event);
  // }

  languageDropdownHTML() {
    return `
      <div class="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-md shadow-lg z-50">
        <a data-language-${this.identifier}-code-param="en" data-action="click->${this.identifier}#changeLanguage" class="block px-4 py-2 text-gray-800 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 cursor-pointer">English</a>
        <a data-language-${this.identifier}-code-param="es" data-action="click->${this.identifier}#changeLanguage" class="block px-4 py-2 text-gray-800 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 cursor-pointer">Spanish</a>
        <a data-language-${this.identifier}-code-param="fr" data-action="click->${this.identifier}#changeLanguage" class="block px-4 py-2 text-gray-800 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 cursor-pointer">French</a>
        <a data-language-${this.identifier}-code-param="de" data-action="click->${this.identifier}#changeLanguage" class="block px-4 py-2 text-gray-800 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 cursor-pointer">German</a>
        <a data-language-${this.identifier}-code-param="vi" data-action="click->${this.identifier}#changeLanguage" class="block px-4 py-2 text-gray-800 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 cursor-pointer">Vietnamese</a>
      </div>
    `
  }

  changeLanguage(event) {
    const languageCode = event.params.languageCode
    this.languageCodeValue = languageCode;
  }

  languageCodeValueChanged(value, previousValue) {
    if (previousValue === undefined) return;
    this.updateTranslations();
    // this.element.innerHTML = this.languageCodeText()[value]
    this.updateLanguageCodeText();
    setCookie('languageCode', value, 365);
    closeSwal();
  }

  updateLanguageCodeText() {
    this.codeTextTarget.textContent = this.languageCodeText()[this.languageCodeValue];
  }

  setLanguageCode(value) {
    this.languageCodeValue = value;
  }

  updateTranslations() {
    this.wordTargets.forEach((element) => {
      const key = element.getAttribute("data-language-key");
      const translation = this.getTranslation(key);
      if (translation) {
        element.textContent = translation;
      }
    });
  }

  getTranslation(key) {
    const dict = window.LanguageDictionary || this.dictionary();
    if (dict[key] && dict[key][this.languageCodeValue]) {
      return dict[key][this.languageCodeValue];
    }
    return null;
  }

  update() {
    this.updateTranslations();
  }

  languageCodeText() {
    return {
      en: "EN",
      es: "ES",
      fr: "FR",
      de: "DE",
      vi: "VI",
    }
  }
  dictionary() {
    return {
      "Hello": {
        en: "Hello",
        es: "Hola",
        fr: "Bonjour",
        de: "Hallo",
        vi: "Xin chào",
      },
      "Hello!": {
        en: "Hello!",
        es: "¡Hola!",
        fr: "Bonjour!",
        de: "Hallo!",
        vi: "Xin chào!",
      },
      "Welcome to our application!": {
        en: "Welcome to our application!",
        es: "¡Bienvenido a nuestra aplicación!",
        fr: "Bienvenue dans notre application!",
        de: "Willkommen in unserer Anwendung!",
        vi: "Chào mừng bạn đến với ứng dụng của chúng tôi!",
      },
      "Logout": {
        en: "Logout",
        es: "Cerrar sesión",
        fr: "Se déconnecter",
        de: "Abmelden",
        vi: "Đăng xuất",
      },
      "Login": {
        en: "Login",
        es: "Iniciar sesión",
        fr: "Se connecter",
        de: "Anmelden",
        vi: "Đăng nhập",
      },
      "Product": {
        en: "Product",
        es: "Producto",
        fr: "Produit",
        de: "Produkt",
        vi: "Sản phẩm",
      },
      "Dashboard": {
        en: "Dashboard",
        es: "Tablero",
        fr: "Tableau de bord",
        de: "Instrumententafel",
        vi: "Bảng điều khiển",
      },
      "Employees": {
        en: "Employees",
        es: "Empleados",
        fr: "Employés",
        de: "Mitarbeiter",
        vi: "Nhân viên",
      },
      "Bookings": {
        en: "Bookings",
        es: "Reservas",
        fr: "Réservations",
        de: "Buchungen",
        vi: "Đặt chỗ",
      },
      "Payments": {
        en: "Payments",
        es: "Pagos",
        fr: "Paiements",
        de: "Zahlungen",
        vi: "Thanh toán",
      },
      "Invoices": {
        en: "Invoices",
        es: "Facturas",
        fr: "Factures",
        de: "Rechnungen",
        vi: "Hóa đơn",
      },
      "Reports": {
        en: "Reports",
        es: "Informes",
        fr: "Rapports",
        de: "Berichte",
        vi: "Báo cáo",
      },
      "Settings": {
        en: "Settings",
        es: "Configuraciones",
        fr: "Paramètres",
        de: "Einstellungen",
        vi: "Cài đặt",
      },
      "Categories": {
        en: "Categories",
        es: "Categorías",
        fr: "Catégories",
        de: "Kategorien",
        vi: "Danh mục",
      },
      "Customers": {
        en: "Customers",
        es: "Clientes",
        fr: "Clients",
        de: "Kunden",
        vi: "Khách hàng",
      },
      "Sales": {
        en: "Sales",
        es: "Ventas",
        fr: "Ventes",
        de: "Verkäufe",
        vi: "Bán hàng",
      },
      "Inventory": {
        en: "Inventory",
        es: "Inventario",
        fr: "Inventaire",
        de: "Inventar",
        vi: "Hàng tồn kho",
      },
      "Add New": {
        en: "Add New",
        es: "Agregar nuevo",
        fr: "Ajouter nouveau",
        de: "Neu hinzufügen",
        vi: "Thêm mới",
      },
      "Search": {
        en: "Search",
        es: "Buscar",
        fr: "Chercher",
        de: "Suchen",
        vi: "Tìm kiếm",
      },
      "Profile": {
        en: "Profile",
        es: "Perfil",
        fr: "Profil",
        de: "Profil",
        vi: "Hồ sơ",
      },
      "Notifications": {
        en: "Notifications",
        es: "Notificaciones",
        fr: "Notifications",
        de: "Benachrichtigungen",
        vi: "Thông báo",
      },
      "Help": {
        en: "Help",
        es: "Ayuda",
        fr: "Aide",
        de: "Hilfe",
        vi: "Trợ giúp",
      },
      "Contact Support": {
        en: "Contact Support",
        es: "Contactar soporte",
        fr: "Contacter le support",
        de: "Support kontaktieren",
        vi: "Liên hệ hỗ trợ",
      },
      "Save": {
        en: "Save",
        es: "Guardar",
        fr: "Enregistrer",
        de: "Speichern",
        vi: "Lưu",
      },
      "Cancel": {
        en: "Cancel",
        es: "Cancelar",
        fr: "Annuler",
        de: "Abbrechen",
        vi: "Hủy",
      },
      "Delete": {
        en: "Delete",
        es: "Eliminar",
        fr: "Supprimer",
        de: "Löschen",
        vi: "Xóa",
      },
      "Edit": {
        en: "Edit",
        es: "Editar",
        fr: "Éditer",
        de: "Bearbeiten",
        vi: "Chỉnh sửa",
      },
      "Update": {
        en: "Update",
        es: "Actualizar",
        fr: "Mettre à jour",
        de: "Aktualisieren",
        vi: "Cập nhật",
      },
      "View": {
        en: "View",
        es: "Ver",
        fr: "Voir",
        de: "Ansehen",
        vi: "Xem",
      },
      "Back": {
        en: "Back",
        es: "Atrás",
        fr: "Retour",
        de: "Zurück",
        vi: "Quay lại",
      },
      "Next": {
        en: "Next",
        es: "Siguiente",
        fr: "Suivant",
        de: "Weiter",
        vi: "Tiếp theo",
      },
      "Previous": {
        en: "Previous",
        es: "Anterior",
        fr: "Précédent",
        de: "Vorherige",
        vi: "Trước",
      },
      "Submit": {
        en: "Submit",
        es: "Enviar",
        fr: "Soumettre",
        de: "Einreichen",
        vi: "Gửi",
      },
      "Reset": {
        en: "Reset",
        es: "Restablecer",
        fr: "Réinitialiser",
        de: "Zurücksetzen",
        vi: "Đặt lại",
      },
      "Language": {
        en: "Language",
        es: "Idioma",
        fr: "Langue",
        de: "Sprache",
        vi: "Ngôn ngữ",
      },
      "Change Password": {
        en: "Change Password",
        es: "Cambiar contraseña",
        fr: "Changer le mot de passe",
        de: "Passwort ändern",
        vi: "Đổi mật khẩu",
      },
      "Old Password": {
        en: "Old Password",
        es: "Contraseña antigua",
        fr: "Ancien mot de passe",
        de: "Altes Passwort",
        vi: "Mật khẩu cũ",
      },
      "New Password": {
        en: "New Password",
        es: "Nueva contraseña",
        fr: "Nouveau mot de passe",
        de: "Neues Passwort",
        vi: "Mật khẩu mới",
      },
      "Confirm Password": {
        en: "Confirm Password",
        es: "Confirmar contraseña",
        fr: "Confirmer le mot de passe",
        de: "Passwort bestätigen",
        vi: "Xác nhận mật khẩu",
      },
      "Password": {
        en: "Password",
        es: "Contraseña",
        fr: "Mot de passe",
        de: "Passwort",
        vi: "Mật khẩu",
      },
      "Username": {
        en: "Username",
        es: "Nombre de usuario",
        fr: "Nom d'utilisateur",
        de: "Benutzername",
        vi: "Tên đăng nhập",
      },
      "Email": {
        en: "Email",
        es: "Correo electrónico",
        fr: "Email",
        de: "E-Mail",
        vi: "Email",
      },
      "Phone": {
        en: "Phone",
        es: "Teléfono",
        fr: "Téléphone",
        de: "Telefon",
        vi: "Điện thoại",
      },
      "Address": {
        en: "Address",
        es: "Dirección",
        fr: "Adresse",
        de: "Adresse",
        vi: "Địa chỉ",
      },
      "City": {
        en: "City",
        es: "Ciudad",
        fr: "Ville",
        de: "Stadt",
        vi: "Thành phố",
      },
      "Country": {
        en: "Country",
        es: "País",
        fr: "Pays",
        de: "Land",
        vi: "Quốc gia",
      },
    }
  }
}
