# CuentasClaras

Aplicación de finanzas personales para iPhone que importa automáticamente cartolas bancarias chilenas de Banco Security desde PDF, las procesa y persiste utilizando SwiftData.

## 📋 Descripción

CuentasClaras es una solución completa para gestionar tus finanzas personales con importación automática de cartolas del Banco Security. La aplicación:

- Importa PDFs de cartolas bancarias
- Extrae y valida transacciones automáticamente
- Persiste datos en SwiftData
- Proporciona visualización clara de saldos y movimientos
- Detecta y previene duplicados mediante fingerprints SHA256
- Valida conciliación contable automáticamente

## 🏗️ Arquitectura

### Patrones Aplicados

- **Feature First**: Organización por dominios (features)
- **Clean Architecture**: Separación clara de responsabilidades
- **MVVM**: Modelos, Vistas, ViewModels
- **Servicios Desacoplados**: Inyección de dependencias
- **Swift Concurrency**: Async/await para operaciones asincrónicas
- **Testeable**: Código diseñado para testing

### Stack Tecnológico

- Swift 6
- SwiftUI
- SwiftData
- PDFKit
- CryptoKit
- Foundation

## 📁 Estructura de Carpetas

```
CuentasClaras/
├── CuentasClarasApp.swift
├── AppDelegate.swift
├── 📁 Core/
│   ├── Models/
│   │   ├── BankAccount.swift
│   │   ├── BankStatement.swift
│   │   ├── Transaction.swift
│   │   ├── AccountSummary.swift
│   │   └── CreditLine.swift
│   ├── Services/
│   │   ├── PDFTextExtractor.swift
│   │   ├── SecurityStatementParser.swift
│   │   ├── SecurityStatementValidator.swift
│   │   ├── ParsedStatementMapper.swift
│   │   ├── SwiftDataStatementImporter.swift
│   │   └── BankStatementImportCoordinator.swift
│   └── Utilities/
│       └── CryptoUtilities.swift
├── 📁 Features/
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   └── DashboardViewModel.swift
│   ├── Statements/
│   │   ├── StatementsView.swift
│   │   ├── StatementsViewModel.swift
│   │   ├── StatementDetailView.swift
│   │   └── StatementDetailViewModel.swift
│   ├── Transactions/
│   │   ├── TransactionDetailView.swift
│   │   └── TransactionDetailViewModel.swift
│   └── ImportStatement/
│       ├── ImportStatementView.swift
│       ├── ImportStatementViewModel.swift
│       └── ImportStatementPreviewView.swift
├── 📁 Tests/
│   ├── SecurityStatementParserTests.swift
│   ├── ClassificationTests.swift
│   ├── ReconciliationTests.swift
│   ├── ImportTests.swift
│   └── ValidatorTests.swift
└── 📁 Resources/
    ├── Assets.xcassets
    └── Localizable.strings
```

## 🏦 Banco Security

### Formato de Cartolas

El parser de Banco Security soporta extractos con registros como:

```
0000309768 7.980 COMPRA MERCADO URBANO TO 01/09 4.087.477
1015910136 TRANSFERENCIA DESDE Chile DE PERSONA 03/09 72.999 2.695.705
```

### Detección Automática

- **Fecha**: Formato DD/MM
- **Documento**: Número de 10 dígitos o RUT
- **Descripción**: Texto descriptivo de la transacción
- **Monto**: Valor en pesos chilenos
- **Saldo**: Saldo resultante

### Clasificación Cargo/Abono

La clasificación se realiza mediante conciliación de saldos:

- **Cargo (Débito)**: `saldoAnterior - monto = saldoActual`
- **Abono (Crédito)**: `saldoAnterior + monto = saldoActual`
- **No Concilia**: `confidence < 1.0`, requiere revisión manual

## 📊 Modelos de Datos

### BankAccount
```swift
@Model
final class BankAccount {
    var bankIdentifier: String
    var name: String
    var accountNumberMasked: String
    var currencyCode: String
    @Relationship(deleteRule: .cascade) var statements: [BankStatement]
    // ...
}
```

### BankStatement
```swift
@Model
final class BankStatement {
    var importFingerprint: String // SHA256
    var statementNumber: String
    var periodStart: Date
    var periodEnd: Date
    var issueDate: Date
    var sourceFileName: String
    var importedAt: Date
    var warnings: [String]
    @Relationship(deleteRule: .cascade) var transactions: [Transaction]
    var accountSummary: AccountSummary?
    var creditLine: CreditLine?
    // ...
}
```

### Transaction
```swift
@Model
final class Transaction {
    var importFingerprint: String // SHA256 único
    var date: Date
    var transactionDescription: String
    var documentNumber: String
    var debitAmount: Decimal?
    var creditAmount: Decimal?
    var resultingBalance: Decimal
    var parserConfidence: Double // 0.0 - 1.0
    var sourcePage: Int
    var sourceRawText: String
    var categoryName: String?
    var requiresReview: Bool
    // ...
}
```

### AccountSummary
```swift
@Model
final class AccountSummary {
    var openingBalance: Decimal
    var totalDebits: Decimal
    var totalCredits: Decimal
    var accountingBalance: Decimal
    var availableBalance: Decimal
    var totalFees: Decimal
    // ...
}
```

### CreditLine
```swift
@Model
final class CreditLine {
    var approvedAmount: Decimal
    var usedAmount: Decimal
    var availableAmount: Decimal
    var isActive: Bool
    // ...
}
```

## 📥 Proceso de Importación

### Flujo Completo

1. **Seleccionar PDF**: Usuario elige archivo de cartola
2. **Extraer Texto**: PDFTextExtractor procesa el PDF
3. **Parsear**: SecurityStatementParser extrae datos
4. **Validar**: SecurityStatementValidator verifica integridad
5. **Mapear**: ParsedStatementMapper convierte a modelos
6. **Preview**: Mostrar resumen antes de confirmar
7. **Importar**: SwiftDataStatementImporter persiste en BD
8. **Detectar Duplicados**: Usar SHA256 de cartola

### Validaciones

- ✓ Validación de cartola: `saldoInicial + totalAbonos - totalCargos = saldoFinal`
- ✓ Validación de movimientos: cada transacción contra saldo previo
- ✓ Cancelación completa si hay inconsistencias
- ✓ Fingerprints SHA256 para prevenir duplicados

## 🎯 Características Principales

### Dashboard
- Visualización del saldo disponible
- Visualización del saldo contable
- Total de cargos del período
- Total de abonos del período
- Información de líneas de crédito

### Cartolas (Statements)
- Listado de cartolas importadas
- Filtrado por período
- Indicadores de advertencias
- Acceso a detalle

### Detalle de Cartola
- Resumen financiero completo
- Información de línea de crédito
- Advertencias de importación
- Listado de movimientos
- Acceso a detalle de transacciones

### Detalle de Transacción
- Fecha y documento
- Descripción completa
- Tipo (cargo/abono)
- Saldo resultante
- Categoría asignada
- Nivel de confianza del parser

## ✅ Validaciones Implementadas

### Conciliación Contable
```
Saldo Inicial: 1.000.000
+ Total Abonos: 500.000
- Total Cargos: 200.000
= Saldo Final: 1.300.000 ✓
```

### Clasificación Cargo/Abono
- Balance de saldos
- Confidence scoring
- Flag para revisión manual
- Validación cruzada

## 🧪 Tests

Cobertura de tests para:

- ✓ Parser Security (extracción de datos)
- ✓ Clasificación de cargos
- ✓ Clasificación de abonos
- ✓ Conciliación contable
- ✓ Detección de duplicados
- ✓ Validación integral

## 🌙 Características de UX

- ✓ Soporte de modo oscuro
- ✓ Accesibilidad VoiceOver
- ✓ Navegación intuitiva
- ✓ Indicadores de estado
- ✓ Manejo de errores transparente

## 🚀 Roadmap

- [x] Estructura base y modelos
- [x] Parser Security
- [x] Validación contable
- [x] Importación a SwiftData
- [x] Interfaz Dashboard
- [x] Interfaz Cartolas
- [x] Interfaz Transacciones
- [x] Tests unitarios
- [ ] Sincronización con múltiples cuentas
- [ ] Categorización automática
- [ ] Reportes analíticos
- [ ] Exportación de datos
- [ ] Sincronización en la nube

## 📸 Capturas (Pendientes)

- Dashboard con saldos y líneas de crédito
- Listado de cartolas importadas
- Detalle de cartola con transacciones
- Vista de importación con preview
- Modo oscuro en todas las vistas

## 📝 Licencia

Proyecto personal - Todos los derechos reservados

---

**Última actualización**: Octubre 2026
