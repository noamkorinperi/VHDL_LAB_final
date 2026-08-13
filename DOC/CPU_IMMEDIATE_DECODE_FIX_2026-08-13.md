# תיקון פענוח immediate בליבת ה-CPU

תאריך: 13.08.2026 15:04 IDT

## תקציר

בדיקות האינטגרציה של GPIO חשפו שתי תקלות קיימות בקוד הבסיס של הליבה:

1. פקודת `LUI` סווגה כ-U-type ב-Control, אך לא קיבלה U-immediate ב-Idecode.
2. פקודות load סווגו כ-I-type ב-Control, אך לא קיבלו I-immediate ב-Idecode.

שתי התקלות נמצאו גם בגרסת המדריך וגם בגרסת Lab 5. תיקיות המקור נשמרו ללא
שינוי; התיקון בוצע רק בעץ הפעיל `DUT/RV32IMscMCU`.

## תקלה 1 — LUI איבד את החלק הגבוה של הכתובת

בקוד המקורי הוגדר:

```vhdl
constant UTYPE_OPC := "0010111" and "0110111";
```

תוצאת ה-AND היא `0010111`, שהוא opcode של `AUIPC`. ב-`CONTROL.VHD` הערך
שימש כמסכה ולכן זיהה גם `AUIPC` וגם `LUI`. ב-`IDECODE.VHD` אותו ערך שימש
כהתאמה מדויקת בתוך `with select`, ולכן `LUI` (`0110111`) נפל ל-`others`
וקיבל immediate אפס.

ההשפעה נצפתה ישירות ב-List של ModelSim:

| כתובת רצויה | כתובת לפני התיקון |
|---:|---:|
| `0x2000` | `0x0000` |
| `0x2004` | `0x0004` |
| `0x2005` | `0x0005` |
| `0x2008` | `0x0008` |
| `0x2009` | `0x0009` |
| `0x200C` | `0x000C` |
| `0x200D` | `0x000D` |

לכן הכתיבות הופנו ל-DTCM במקום ל-MMIO.

### תיקון

ב-`const_package.vhd` הוגדרו opcodes מפורשים ונפרדים:

```vhdl
constant AUIPC_OPC : std_logic_vector(6 downto 0) := "0010111";
constant LUI_OPC   : std_logic_vector(6 downto 0) := "0110111";
```

ה-Control בודק כל opcode במפורש, וה-Idecode בוחר U-immediate עבור שתי
האפשרויות:

```vhdl
when AUIPC_OPC | LUI_OPC
```

## תקלה 2 — offset של פקודות load היה תמיד אפס

לאחר תיקון LUI, ה-benchmark הגיע לכתובת הבסיס `0x2000`, אך הפקודה:

```asm
lw t4, 16(t4)
```

יצרה `0x2000` במקום `0x2010`. הסיבה הייתה ש-`IDECODE.VHD` בחר
`SignExt_Iimm_w` עבור arithmetic I-type ו-`JALR`, אך לא עבור opcode של
load (`0000011`). לכן offset‏ `16` הוחלף באפס, והקריאה בוצעה מ-LEDR במקום
מ-PORT_SW.

### תיקון

נוסף:

```vhdl
constant LOAD_OPC : std_logic_vector(6 downto 0) := "0000011";
```

ובחירת ה-immediate עודכנה:

```vhdl
when ITYPE_OPC | LOAD_OPC
```

## תיקון דיוק ב-testbench

ה-bus של הליבה הוא combinational והכתיבה ל-GPIO מתבצעת בקצה העולה. שני
testbenches של האינטגרציה דגמו את ה-bus שתי ננו-שניות אחרי הקצה, ולכן ראו
את הפקודה הבאה ולא את הטרנזקציה שבוצעה בקצה. הדגימה הועברה לרגע הקצה
העולה, ולאחר סיום הספירה נוסף delay קצר רק לפני בדיקת יציאות הרגיסטרים.

השינוי ב-testbench אינו מסתיר כשל DUT: לפני תיקון ה-opcodes נצפו בפועל
כתובות שגויות. הוא רק מבטיח שהמונה ב-TB והיציאה הפיזית מתייחסים לאותה
טרנזקציה.

## אימות לאחר התיקון

| בדיקה | תוצאה | זמן סימולציה |
|---|---|---:|
| Stage 0 baseline regression | PASS | 6222 ns |
| Stage 2 GPIO unit | PASS (הרצת משתמש לפני התיקון; הרכיב לא השתנה) | 223 ns |
| Stage 2 GPIO/test0 integration | PASS | 2462 ns |
| Stage 2 GPIO test1/test2 + SW0 | PASS | 2342 ns |
| Quartus Analysis & Synthesis | PASS — 0 errors, 13 warnings | 13.08.2026 15:08 IDT |

אזהרות U/X שנצפו ב-0 ps הן אזהרות אתחול קיימות. לא הופיעו assertion
failures לאחר התיקון.

## קבצים פעילים ששונו

- `DUT/RV32IMscMCU/const_package.vhd`
- `DUT/RV32IMscMCU/CONTROL.VHD`
- `DUT/RV32IMscMCU/IDECODE.VHD`
- `TB/RV32IMscMCU/tb_stage2_gpio_integration.vhd`
- `TB/RV32IMscMCU/tb_stage2_gpio_switch_benchmarks.vhd`

קובצי ה-benchmark וקובצי ה-hex הושוו למקור ולא שונו.
