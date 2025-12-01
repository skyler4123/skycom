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
      hello: {
        en: "Hello",
        es: "Hola",
        fr: "Bonjour",
        de: "Hallo",
        vi: "Xin chào",
      },
      welcome_message: {
        en: "Welcome to our application!",
        es: "¡Bienvenido a nuestra aplicación!",
        fr: "Bienvenue dans notre application!",
        de: "Willkommen in unserer Anwendung!",
        vi: "Chào mừng bạn đến với ứng dụng của chúng tôi!",
      },
      logout: {
        en: "Logout",
        es: "Cerrar sesión",
        fr: "Se déconnecter",
        de: "Abmelden",
        vi: "Đăng xuất",
      },
      login: {
        en: "Login",
        es: "Iniciar sesión",
        fr: "Se connecter",
        de: "Anmelden",
        vi: "Đăng nhập",
      },
      product: {
        en: "Product",
        es: "Producto",
        fr: "Produit",
        de: "Produkt",
        vi: "Sản phẩm",
      },
      dashboard: {
        en: "Dashboard",
        es: "Tablero",
        fr: "Tableau de bord",
        de: "Instrumententafel",
        vi: "Bảng điều khiển",
      },
      employees: {
        en: "Employees",
        es: "Empleados",
        fr: "Employés",
        de: "Mitarbeiter",
        vi: "Nhân viên",
      },
      bookings: {
        en: "Bookings",
        es: "Reservas",
        fr: "Réservations",
        de: "Buchungen",
        vi: "Đặt chỗ",
      },
      payments: {
        en: "Payments",
        es: "Pagos",
        fr: "Paiements",
        de: "Zahlungen",
        vi: "Thanh toán",
      },
      invoices: {
        en: "Invoices",
        es: "Facturas",
        fr: "Factures",
        de: "Rechnungen",
        vi: "Hóa đơn",
      },
      reports: {
        en: "Reports",
        es: "Informes",
        fr: "Rapports",
        de: "Berichte",
        vi: "Báo cáo",
      },
      settings: {
        en: "Settings",
        es: "Configuraciones",
        fr: "Paramètres",
        de: "Einstellungen",
        vi: "Cài đặt",
      },
      categories: {
        en: "Categories",
        es: "Categorías",
        fr: "Catégories",
        de: "Kategorien",
        vi: "Danh mục",
      },
    }
  }
}
