// Require a global dictionary object named "LanguageDictionary", so we can override it if needed in other Stimulus controllers
// Expect element have attribute for initialize targets "word": data-language-key="value"
// Ex: data-language-key="hello" will be inserted "Hello" text in English language by a dictionary object based on pathname
// This Stimulus controller also listen to change event of languageCodeValue to update all targets' text content
// This Stimulus controller require targets contain only text content, not HTML content

import ApplicationController from "controllers/application_controller";

export default class LanguageController extends ApplicationController {
  static targets = ["word"];
  static values = {
    languageCode: { type: String, default: "en" },
  }

  initialize() {
    this.initDictionary();
    this.initTargets();
  }

  initDictionary() {
    window.LanguageDictionary = this.dictionary();
  }

  initTargets() {
    this.element.querySelectorAll("[data-language-key]").forEach((element) => {
      element.setAttribute(`data-${this.identifier}-target`, "word");
    });
  }

  languageCodeValueChanged(value, previousValue) {
    this.updateTranslations();
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
    }
  }
}
