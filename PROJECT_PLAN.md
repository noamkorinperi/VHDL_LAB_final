# תוכנית עבודה ומעקב - RV32IM MCU על DE10-Standard

עודכן לאחרונה: 17.08.2026 21:36 IDT - תיקון ה-stall עבר גם Quartus Analysis & Synthesis

מסמך זה הוא מקור המעקב השוטף של הפרויקט. מעדכנים אותו בכל מעבר שלב, לאחר בדיקה שעברה, וכאשר מתגלה חסם או שינוי בדרישות.

## תמונת מצב נוכחית

| נושא | מצב |
|---|---|
| כרטיס יעד | DE10-Standard |
| ארכיטקטורת חובה | RV32IM single-cycle MCU |
| זמן עדכון אחרון | 17.08.2026 21:36 IDT |
| שלב נוכחי | שלבים 0–2 עברו ותועדו; שתי בדיקות שלב 3 עברו אוטומטית, ונשאר לשמור ראיית GUI לאינטגרציה |
| הושלם | baseline, interconnect ו-GPIO כולל test0-test2; Divider unit ו-CPU/Divider integration עברו |
| הפעולה הבאה | להריץ ב-GUI את בדיקת CPU/Divider integration המתוקנת ולשמור צילום, Wave ו-List |
| חסם נוכחי | אין; תיקוני האינטגרציה עברו רגרסיה אוטומטית |
| Quartus | Analysis & Synthesis לאחר תיקון ה-stall עבר עם 0 errors ו-13 warnings |
| בונוסים | Pipeline ו-UART מוקפאים עד השלמת כל דרישות החובה |

### מקרא מצבים וחותמות זמן

- `[x | DD.MM.YYYY HH:MM IDT]` הושלם ונבדק בזמן המצוין.
- `[x | אומת DD.MM.YYYY HH:MM IDT]` בוצע קודם, אך זהו זמן האימות הראשון המתועד.
- `[~ | DD.MM.YYYY HH:MM IDT]` התחיל או עודכן כעת.
- `[ ]` טרם התחיל.
- `[! | DD.MM.YYYY HH:MM IDT]` חסום, נדחה או דורש החלטה מאז הזמן המצוין.
- `[- | DD.MM.YYYY HH:MM IDT]` מחוץ להיקף הפעיל מאז הזמן המצוין.

כל שינוי עתידי בסטטוס חייב לכלול תאריך, שעה ואזור זמן. אין לשכתב חותמת
היסטורית: שינוי נוסף מקבל חותמת חדשה ונרשם גם ביומן הביצוע.

## מפת הדרך

| שלב | חבילת עבודה | תוצר מרכזי | מצב |
|---:|---|---|---|
| 0 | סביבת עבודה ו-baseline | ליבת RV32IM הקיימת עוברת ModelSim | `[x | 13.08.2026 14:00 IDT]` |
| 1 | ארכיטקטורת MCU | Top-Level, מפת כתובות וממשקי bus מוגדרים | `[x | 12.08.2026 20:44 IDT]` |
| 2 | GPIO ממופה זיכרון | LEDs, HEX ו-switches עובדים ב-ModelSim | `[x | 13.08.2026 15:04 IDT]` |
| 3 | Divider Accelerator | `DIV/REM` וה-handshake עוברים בדיקות | `[~ | 17.08.2026 21:34 IDT]` - שתי הבדיקות עברו; ראיית GUI לאינטגרציה ממתינה |
| 4 | Basic Timer | counter, compare, PWM ו-capture עובדים | `[ ]` |
| 5 | Pushbuttons | KEY1-KEY3 מסונכרנים, עוברים debounce ומייצרים אירוע יחיד | `[ ]` |
| 5.5 | בדיקת חומרה מוקדמת | KEY1-KEY3 ו-PWM מודגמים פיזית על DE10-Standard | `[ ]` |
| 6 | Interrupt Controller | IE, IFG, TYPE ותעדוף עובדים | `[ ]` |
| 7 | פסיקות בתוך ה-CPU | כניסה ל-ISR וחזרה ממנו עובדות לפי הפרוטוקול | `[ ]` |
| 8 | אינטגרציה ואימות מלא | benchmarks עוברים מול RARS | `[ ]` |
| 9 | Quartus ו-DE10-Standard | קומפילציה, pin assignment וקובץ SOF | `[ ]` |
| 10 | SignalTap ו-PPA | הוכחת FPGA ודוחות Area/Fmax/Power | `[ ]` |
| 11 | דוח והגשה | `Final_report.pdf` ו-ZIP נקיים לפי המבנה הנדרש | `[ ]` |

---

## יומן ביצוע ושינויים בפועל

### 17.08.2026 21:36 IDT - סינתזה לאחר תיקון ה-stall

- Quartus Analysis & Synthesis עבר על הגרסה הסופית של תיקון ה-Divider.
- תוצאה: 0 errors ו-13 warnings; אלו אותן אזהרות לא חוסמות שתועדו קודם.

### 17.08.2026 21:34 IDT - תיקון stall ואימות אינטגרציית ה-Divider

- בדיקת האינטגרציה נכשלה תחילה ב-782 ns משום שה-PC השתנה בזמן `div_busy`.
- נמצא ש-`IFETCH` שמר את רגיסטר ה-PC בזמן stall, אך כתובת ITCM המשיכה להיגזר מ-`next_pc_w`; לכן ה-decode עבר לפקודה הבאה מוקדם מדי.
- בזמן stall כתובת ITCM נלקחת כעת מ-`pc_q`, ונוסף מצב retire שמשאיר את פקודת ה-DIV עד קצה ה-write-back ומשחרר אותה פעם אחת בלבד.
- התיקון תומך גם בשתי פקודות Divider עוקבות ואינו מאפשר שיגור כפול של אותה פקודה.
- אינטגרציית CPU/Divider עברה ב-20462 ns; לאחר מכן עברו גם כל שש בדיקות הרגרסיה האחרות של שלבים 0–3.
- נוסף `DOC/DIVIDER_STALL_FIX_2026-08-17.md` עם ניתוח התקלה והאימות.
- ראיות ה-GUI של Divider unit נשמרו; נשאר לשמור את ראיות ה-GUI של האינטגרציה המתוקנת.

### 17.08.2026 21:21 IDT - תיקון והרצת Divider unit

- בהרצה הראשונה `const_package.vhd` לא התקמפל משום שהסקריפט לא קימפל קודם את `cond_compilation_package.vhd`.
- סדר הקומפילציה ב-`run_stage3_divider_unit.do` תוקן בהתאם ל-`COMPILE_ORDER.txt` ולסקריפט האינטגרציה.
- הרצת console מלאה עברה עם 0 errors ו-0 warnings והתקבלה ההודעה `STAGE 3 DIVIDER UNIT PASS` ב-5661 ns.
- עדיין נדרשת הרצה חוזרת ב-GUI לשמירת Wave/List, ולאחריה בדיקת CPU/Divider integration.

### 17.08.2026 21:19 IDT - הושלם תיעוד GUI של שלב 2

- נשמרו צילום מסך, Wave ו-List עבור `GPIO/test0` integration.
- נשמרו צילום מסך, Wave ו-List עבור בדיקות `GPIO/test1` ו-`GPIO/test2` עם switches.
- בכך הושלם גם תיעוד הראיות של שלב 2, מעבר להרצות האוטומטיות שכבר עברו.

### 13.08.2026 15:08 IDT - סינתזה חוזרת לאחר תיקוני ה-CPU

- Quartus Prime Lite 21.1 Analysis & Synthesis עבר לאחר תיקוני LUI/load.
- תוצאה: 0 errors ו-13 warnings; לא נוספה אזהרה חדשה שחוסמת את התכנון.
- נשמר אותו פרופיל חומרה צפוי: PLL אחד, 4 DSP ו-64 מקטעי RAM.

### 13.08.2026 15:04 IDT - תיקון פענוח immediate וסגירת שלב 2

- בדיקת `GPIO/test0` נכשלה תחילה משום שהמעבד יצר `0x0000/4/5/...` במקום `0x2000/4/5/...`.
- נמצא שקבוע U-type מקורי שימש גם כמסכה וגם כ-opcode מדויק; `LUI` קיבל immediate אפס.
- הוגדרו `AUIPC_OPC` ו-`LUI_OPC` בנפרד והפענוח עודכן בשני המקומות.
- בדיקת `test1/test2` חשפה בנוסף ש-load לא קיבל I-immediate; נוסף `LOAD_OPC` לפענוח.
- דגימת ה-bus בשני integration TBs הותאמה לקצה שבו טרנזקציית GPIO מתבצעת.
- רגרסיית שלב 0 עברה ב-6222 ns, ‏GPIO/test0 עבר ב-2462 ns ו-test1/test2 עברו ב-2342 ns.
- נוסף `DOC/CPU_IMMEDIATE_DECODE_FIX_2026-08-13.md` עם ניתוח מלא וראיות.

### 13.08.2026 14:18 IDT - GPIO unit test עבר

- התקבלה ההודעה `STAGE 2 GPIO UNIT PASS` בזמן סימולציה 223 ns.
- נשמרו Wave, ‏List וצילום מסך בתיקיית הראיות של שלב 2.

### 13.08.2026 14:11 IDT - בדיקת interconnect עברה

- התקבלה ההודעה `STAGE 1 INTERCONNECT PASS` בזמן סימולציה 5 ns.
- נשמרו Wave, ‏List וצילום מסך בתיקיית הראיות של שלב 1.

### 13.08.2026 14:05 IDT - שמירת List אוטומטית בבדיקות ModelSim

- כל שבעת קובצי ה-`.do` עודכנו כך שהאותות של Wave מתווספים גם לחלון List.
- כל הרצה שומרת אוטומטית קובץ `*_list.do` באמצעות `write format list`.
- מסמך הבדיקות עודכן עם רשימת שבעת קובצי ה-List הצפויים.

### 13.08.2026 14:00 IDT - שלב 0 עבר ב-ModelSim

- התקבלה ההודעה `STAGE 0 PASS: RV32I/MUL baseline and DTCM regression` בזמן סימולציה 6222 ns.
- נשמרו `stage0_baseline.log`, צילום Wave וקובץ Wave בתיקיית `screenshots/stage 0`.
- אזהרות arithmetic operand מסוג U/X הופיעו רק בזמן 0 ps ולא מנעו PASS.

### 12.08.2026 21:58 IDT - הוכן מסמך העבודה למחר

- נוסף `DOC/TOMORROW_MODELSIM_CHECKLIST.md` עם הכנה מדויקת וסדר שבע ההרצות.
- לכל בדיקה תועדו פקודת ההרצה, הודעת PASS, אותות לבדיקה וקובץ ה-log הצפוי.
- תועדו נוהל עצירה בכשל, טיפול בספריית `altera_mf` ותבנית דיווח מסכמת.

### 12.08.2026 21:53 IDT - נוסף שלב 5.5 לבדיקת חומרה מוקדמת

- נקבע checkpoint פיזי לאחר השלמת בדיקות ModelSim של שלבים 4–5.
- הבדיקה תכסה KEY1-KEY3 מסונכרנים ועם debounce, וכן יציאת PWM מה-Basic Timer.
- שלב 5.5 אינו מחליף את אימות המערכת המלא על הכרטיס בשלבים 9–10.

### 12.08.2026 21:46 IDT - העלאה ל-GitHub

- המאגר המקומי חובר אל `https://github.com/noamkorinperi/VHDL_LAB_final.git`.
- ה-commit הראשוני שנוצר באתר נשמר ומוזג להיסטוריה המקומית ללא מחיקה.
- הענף `main` הועלה בהצלחה והוגדר לעקוב אחרי `origin/main`.
- המאגר מוגדר כ-Public בהתאם לאישור המפורש של המשתמש להעלות את הפרויקט כפי שהוא.

### 12.08.2026 21:37 IDT - הקמת בקרת גרסאות

- אותחל מאגר Git מקומי על הענף `main`.
- עודכן `.gitignore` כך שתוצרי Quartus ו-ModelSim לא ייכנסו להיסטוריה.
- הוכן checkpoint ראשון בשם `Stage 3 implementation ready for ModelSim`.
- נוסף `README.md` לניווט מהיר בפרויקט ובתיעוד.

### 12.08.2026 21:32 IDT - כיסוי GPIO/test1 ו-GPIO/test2

- נוספו עותקים ייעודיים של קובצי הזיכרון עבור `GPIO/test1` ו-`GPIO/test2`.
- נוספו TB ו-script שמריצים את שני ה-benchmarks במקביל, מגרים את SW0 ובודקים כתיבות LEDR/HEX.
- שלב 2 מוכן כעת לבדיקת כל שלושת ה-benchmarks שסופקו, בלי החלפת קבצים ידנית.

### 12.08.2026 21:30 IDT - Quartus סופי לאחר סנכרון הממשקים

- Analysis & Synthesis חוזר עבר עם 0 errors ו-13 warnings לאחר עדכון כל הצהרות ה-components.
- דוח הסיום מאשר 1,666 registers, ‏131,072 block-memory bits, ‏4 DSP blocks ו-PLL אחד.
- לא נמצאו בדוח אזהרות latch, multiple constant drivers או combinational loop.

### 12.08.2026 21:28 IDT - בדיקה נפרדת לשלב 1

- נוספו `tb_stage1_interconnect.vhd` ו-`run_stage1_interconnect.do` כדי שלכל שלב 0–3 תהיה בדיקה עצמאית.
- הבדיקה מכסה DTCM word addressing, שמירת כתובת MMIO מלאה, read mux, write isolation וכתובת unmapped.

### 12.08.2026 21:25 IDT - שלבים 2–3 מוכנים לבדיקה

- ה-CPU הוסב ל-data bus חיצוני ונוספו `mcu_interconnect` ו-`gpio_peripheral`.
- מומשו LEDR, ששת ה-HEX, encoder active-low וקריאת SW עם zero extension.
- מומשו `divider_unsigned` ו-`divider_accelerator` עבור `DIV/DIVU/REM/REMU`, כולל מקרי קצה ו-CDC.
- נוספו stall ל-IFETCH ומדיניות write-back יחיד בפולס `done`.
- ה-top עודכן ל-sysclk של 25 MHz ול-DIVCLK של 50 MHz באמצעות PLL ל-Cyclone V.
- נוספו חמישה testbenches וחמישה scripts עצמאיים של ModelSim, וכן הוראות הרצה ב-`DOC/MODELSIM_TESTS_STAGE0_TO_STAGE3.md`.
- Quartus Analysis & Synthesis עבר על המימוש המשולב עם 0 errors ו-13 warnings: 1,666 registers, ‏131,072 memory bits, ‏4 DSP ו-PLL אחד.
- בדיקות ModelSim עצמן לא הורצו, בהתאם לבקשת המשתמש; לכן שלבים 2–3 מסומנים "מוכן לבדיקה" ולא "עבר".

### 12.08.2026 20:59 IDT - מדיניות חותמות זמן

- פורמט הסטטוס שונה כך שכל השלמה, דחייה או התחלת עבודה כוללת תאריך ושעה.
- פעולות היסטוריות שזמן יצירת הקובץ שלהן ידוע קיבלו את הזמן המתועד בפועל.
- פעולות שקדמו למעקב הקבצים סומנו באמצעות `אומת`, כדי לא להציג זמן ביצוע מומצא.

### 12.08.2026 20:44 IDT - סגירת תיעוד שלב 1

- נוצר `DOC/PHASE_1_STATUS.md`.
- שלב 1 סומן כמוכן לאחר בדיקת התוצרים ודוח Quartus.
- משימות ModelSim של שלב 0 סומנו כנדחות לבקשת המשתמש.

### 12.08.2026 20:42 IDT - Quartus Analysis & Synthesis

- Analysis & Synthesis הסתיים בהצלחה עם 0 errors.
- נשמרו `RV32IMscMCU.map.rpt` ו-`RV32IMscMCU.map.summary`.
- ה-warnings סווגו ותועדו; לא נמצא כשל elaboration או שגיאת VHDL.

### 12.08.2026 20:34 IDT - ארכיטקטורה ושלד Quartus

- נוספו `mcu_memory_map_pkg.vhd`, ‏`RV32IMscMCU.vhd` ו-`COMPILE_ORDER.txt`.
- נוצרו `DOC/ARCHITECTURE.md` וקובצי `.qpf/.qsf/.sdc`.
- נקבעו Top-Level, מפת הכתובות, ממשק ה-bus ותוכנית clocks/reset.

### 12.08.2026 20:31 IDT - ניידות זיכרונות

- נתיבי `ITCM.hex` ו-`DTCM.hex` המוחלטים הוחלפו ב-generics ניידים.
- יעד הזיכרונות עודכן ל-`Cyclone V`.

### 12.08.2026 20:29 IDT - הקמת עץ העבודה

- נוצרו `DUT`, ‏`TB`, ‏`SIM`, ‏`DOC` ו-`Quartus`.
- קובצי ה-single-cycle מ-Lab 5 הועתקו לעץ העבודה בלי לשנות את המקורות.

### 12.08.2026 20:12 IDT - אימות חומרי הקלט

- אומתו מסמך הדרישות, התמלול, קוד המעבדה וה-benchmarks.
- אומתו זוגות `ITCM.hex`/`DTCM.hex` עבור RV32IM, GPIO ופסיקות.
- תועד כרטיס היעד DE10-Standard.

### סיכום השינויים של שלבים 0-1

מצב מקורות:

- תיקיות `מעבדה קודמת שלנו`, `קבצים מהמדריך` ו-`Benchmark apps` נשמרו ללא שינוי.
- עץ העבודה החדש נוצר בתיקיות `DUT`, `TB`, `SIM`, `DOC` ו-`Quartus`.
- בסיס המימוש הפעיל נלקח מגרסת ה-RV32IM single-cycle של Lab 5, ולא מגרסת ה-RV32I המקורית של המנחה.

שינויים בקובצי Lab 5 שהועתקו לעץ העבודה:

| קובץ | שינוי שבוצע כעת |
|---|---|
| `IFETCH.VHD` | הנתיב המוחלט ל-`ITCM.hex` הוחלף ב-generic בשם `INIT_FILE`; משפחת היעד עודכנה ל-`Cyclone V` |
| `DMEMORY.VHD` | הנתיב המוחלט ל-`DTCM.hex` הוחלף ב-generic בשם `INIT_FILE`; משפחת היעד עודכנה ל-`Cyclone V` |
| `RV32I_CORE.vhd` | נוספו `ITCM_INIT_FILE` ו-`DTCM_INIT_FILE` והם מועברים לרכיבי הזיכרון |
| `aux_package.vhd` | הצהרות ה-generics עודכנו בהתאם לנתיבי הזיכרון הניידים |

קובצי DUT חדשים:

- `mcu_memory_map_pkg.vhd` - מקור אמת יחיד לכתובות MMIO ולערכי interrupt TYPE.
- `RV32IMscMCU.vhd` - Top-Level מבני יציב עבור המערכת והכרטיס.
- `COMPILE_ORDER.txt` - סדר קומפילציה מתועד ל-VHDL-2008.

תשתיות חדשות:

- פרויקט Quartus: `RV32IMscMCU.qpf`, `RV32IMscMCU.qsf` ו-`RV32IMscMCU.sdc`.
- עותקים מקומיים של `ITCM.hex` ו-`DTCM.hex` עבור SIM ו-Quartus.
- `DOC/ARCHITECTURE.md`, `DOC/PHASE_1_STATUS.md` ו-`DOC/Readme.txt`.
- `.gitignore` עבור תוצרי Quartus, ModelSim ועורכים.

מה הוחרג או נדחה:

- אף קובץ מקור לא נמחק.
- `PLL.vhd` הישן נשאר בעץ ה-DUT אך אינו נכלל בבניית שלב 1, מפני שהוא נוצר עבור Cyclone II.
- שלב 1 משתמש זמנית ב-`CLOCK_50` ישירות; יחידת clock/reset ל-Cyclone V תתווסף לפני שילוב המחלק.
- ה-Top-Level הנוכחי מחזיק את HEX כבויים ומשתמש ב-LEDR עבור observability זמנית; GPIO אמיתי יחליף זאת בשלב 2.
- SW ו-KEY1-KEY3 עדיין אינם מחוברים ללוגיקה פונקציונלית.
- קומפילציה והרצה ב-ModelSim, השוואת RARS ו-waveforms נדחו ליום ModelSim.

אימות שבוצע:

- כתובות ה-MMIO הושוו לקובצי `io_map.s` של ה-benchmarks.
- Quartus Prime Lite 21.1 Analysis & Synthesis עבר עם 0 errors.
- תוצאת synthesis ראשונית: 1,271 registers, ‏131,072 block-memory bits ו-4 DSP blocks.
- ה-warnings שנותרו נבדקו ומתועדים ב-`DOC/PHASE_1_STATUS.md`.

---

## שלב 0 - סביבת עבודה ובדיקת baseline

מטרה: להוכיח שהבסיס מהמעבדה הקודמת תקין לפני שמוסיפים MCU או משנים את המעבד.

- [x | אומת 12.08.2026 20:12 IDT] נאספה ליבת RV32IM single-cycle מהמעבדה הקודמת.
- [x | אומת 12.08.2026 20:12 IDT] נאספו testbenches וקובצי ModelSim `.do`.
- [x | אומת 12.08.2026 20:12 IDT] נאספו benchmark, Assembly וזוגות `ITCM.hex`/`DTCM.hex`.
- [x | אומת 12.08.2026 20:12 IDT] נשמרו בנפרד קוד ה-single-cycle, קוד ה-pipeline וחומר המקור מהמדריך.
- [x | אומת 12.08.2026 20:12 IDT] נקבע כרטיס היעד: DE10-Standard.
- [x | 12.08.2026 20:29 IDT] ליצור עץ עבודה חדש בלי לשנות את חומרי המקור.
- [x | 12.08.2026 20:29 IDT] להעתיק לעץ העבודה רק את קובצי ה-single-cycle הנדרשים.
- [x | 12.08.2026 20:31 IDT] להחליף נתיבי HEX קשיחים במנגנון נייד ומתועד.
- [x | 12.08.2026 20:34 IDT] לקבוע סדר קומפילציה אחיד ל-VHDL-2008.
- [! | 12.08.2026 20:44 IDT] לקמפל את הליבה ואת `tb_RV32IM` ב-ModelSim ללא שגיאות - נדחה ליום ModelSim.
- [! | 12.08.2026 20:44 IDT] להריץ את benchmark ה-RV32IM הידני - נדחה ליום ModelSim.
- [! | 12.08.2026 20:44 IDT] להריץ את גרסת ה-GCC אם היא תואמת לתת-הקבוצה הנתמכת בליבה - נדחה ליום ModelSim.
- [! | 12.08.2026 20:44 IDT] להשוות את תוצאת DTCM לתוצאת RARS - נדחה ליום ModelSim.
- [! | 12.08.2026 20:44 IDT] לשמור log ו-waveform קצרים כהוכחת baseline - נדחה ליום ModelSim.
- [ ] ליצור checkpoint מקומי לפני השינוי הפונקציונלי הראשון.

שער יציאה: הליבה הקיימת מתקמפלת, מסיימת benchmark, ותוצאת הזיכרון תואמת ל-golden model.

## שלב 1 - תכנון ארכיטקטורת ה-MCU

מטרה: לסגור את החיבורים והכתובות לפני כתיבת רכיבים חדשים.

- [x | 12.08.2026 20:34 IDT] להכין תרשים Top-Level מבני של CPU, ITCM, DTCM, GPIO, Divider, Timer ו-Interrupt Controller.
- [x | 12.08.2026 20:34 IDT] להגדיר ממשק data bus אחיד: כתובת, נתוני כתיבה, נתוני קריאה, `MemRead` ו-`MemWrite`.
- [x | 12.08.2026 20:34 IDT] להפריד בין DTCM בטווח `0x0000-0x1FFC` לבין MMIO בטווח `0x2000-0x3FFC`.
- [x | 12.08.2026 20:34 IDT] ליצור package יחיד עבור כתובות MMIO, מסכות וקבועי מערכת.
- [x | 12.08.2026 20:34 IDT] להגדיר byte-addressing עבור רגיסטרים סמוכים כמו `HEX0/HEX1` ו-`IE/IFG/TYPE`.
- [x | 12.08.2026 20:34 IDT] להגדיר read mux ו-address decoder ללא יותר מדרייבר אחד על bus הקריאה.
- [x | 12.08.2026 20:34 IDT] להגדיר clock/reset domains: `CLOCK_50`, שעון ליבה, `DIVCLK`, reset מ-KEY0 ו-PLL lock.
- [x | 12.08.2026 20:34 IDT] להגדיר handshake בין ה-CPU למחלק ואת מדיניות עצירת הליבה בזמן חלוקה.
- [x | 12.08.2026 20:34 IDT] להגדיר ממשק `INTR/INTA` ו-FSM הכניסה לפסיקה.
- [x | 12.08.2026 20:34 IDT] לתעד רוחב, כיוון ופולריות של כל אות Top-Level.
- [x | 12.08.2026 20:34 IDT] ליצור שלד Quartus ראשוני עם `.qpf/.qsf` עבור DE10-Standard לאחר ששמות ה-Top-Level והקבצים יציבים.
- [x | 12.08.2026 20:42 IDT] לבצע Analysis & Synthesis ראשוני ולשמור רשימת warnings לבדיקה.
- [x | 12.08.2026 20:44 IDT] לקבוע שכל milestone פונקציונלי מסתיים גם בבדיקת synthesis, לא רק ב-ModelSim.

### מפת כתובות מחייבת

| רכיב | כתובת | רזולוציה |
|---|---:|---|
| DTCM | `0x0000-0x1FFC` | Word storage, byte address space |
| `PORT_LEDR` | `0x2000` | Byte |
| `PORT_HEX0` | `0x2004` | Byte |
| `PORT_HEX1` | `0x2005` | Byte |
| `PORT_HEX2` | `0x2008` | Byte |
| `PORT_HEX3` | `0x2009` | Byte |
| `PORT_HEX4` | `0x200C` | Byte |
| `PORT_HEX5` | `0x200D` | Byte |
| `PORT_SW` | `0x2010` | Byte |
| `PORT_PB` | `0x2014` | Byte |
| UART bonus | `0x2018-0x201A` | Byte, שמור בלבד כרגע |
| `BTCTL1` | `0x201C` | Byte |
| `BTCTL2` | `0x201D` | Byte |
| `BTCMPR0` | `0x2020` | Word |
| `BTCMPR1` | `0x2024` | Word |
| `BTCAPR` | `0x2028` | Word |
| `IE` | `0x202C` | Byte |
| `IFG` | `0x202D` | Byte |
| `TYPE` | `0x202E` | Byte |

שער יציאה: תרשים, package כתובות, bus specification ותוכנית clocks/resets מאושרים ועקביים עם ה-benchmarks.

## שלב 2 - Memory-Mapped GPIO

מטרה: להריץ תחילה MCU שימושי ללא פסיקות.

- [x | 12.08.2026 21:25 IDT] לממש רגיסטר פלט עבור `LEDR7-LEDR0`.
- [x | 12.08.2026 21:25 IDT] לממש שישה רגיסטרים עבור `HEX0-HEX5`.
- [x | 12.08.2026 21:25 IDT] לממש 7-segment encoder בהתאם לפולריות של DE10-Standard.
- [x | 12.08.2026 21:25 IDT] לממש קריאת `SW7-SW0`.
- [x | 12.08.2026 21:25 IDT] לחבר address decoder ו-read mux ל-DTCM ול-GPIO.
- [x | 12.08.2026 21:25 IDT] להבטיח שכתיבה ל-MMIO אינה כותבת במקביל ל-DTCM.
- [x | 12.08.2026 21:25 IDT] ליצור testbench ממוקד עבור read/write של כל כתובת.
- [! | 12.08.2026 21:32 IDT] להריץ `GPIO/test0`, אחריו `test1` ו-`test2` - נדחה ליום ModelSim; שלושתם מוכנים בבדיקות integration אוטומטיות.
- [x | 12.08.2026 21:25 IDT] לבדוק בתכן את reset מ-KEY0 והתנהגות שמירת ערכי פלט; אימות waveform ממתין ל-ModelSim.

שער יציאה: שלושת benchmarks של GPIO עוברים ב-ModelSim והיציאות תואמות לתוכנית ה-Assembly.

## שלב 3 - Divider Accelerator

מטרה: להשלים את פעולות החלוקה של RV32IM באמצעות מחלק רב-מחזורי.

- [x | 12.08.2026 21:25 IDT] לאשר מתוך ה-benchmark ומפרט RV32M אילו פקודות נדרשות: `DIV`, `DIVU`, `REM`, `REMU`.
- [x | 12.08.2026 21:25 IDT] לממש מחלק unsigned של 32 ביט בשיטת shift/subtract.
- [x | 12.08.2026 21:25 IDT] להפיק quotient ו-remainder לאחר 32 מחזורי `DIVCLK`.
- [x | 12.08.2026 21:25 IDT] להגדיר `start`, `busy`, `done` וטעינת operands חד-פעמית.
- [x | 12.08.2026 21:25 IDT] לטפל בסימן מחוץ לליבת המחלק עבור פעולות signed.
- [x | 12.08.2026 21:25 IDT] לטפל במקרי קצה: divisor אפס, overflow וסימני operands.
- [x | 12.08.2026 21:25 IDT] לממש CDC מסודר בין שעון הליבה ל-`DIVCLK`.
- [x | 12.08.2026 21:25 IDT] לעצור את הליבה בלי לבצע פקודה או write-back פעמיים.
- [x | 12.08.2026 21:25 IDT] ליצור testbench עצמאי עם reference model ומקרי קצה.
- [x | 12.08.2026 21:25 IDT] להוסיף בדיקות instruction-level בתוך הליבה.

שער יציאה: כל תוצאות quotient/remainder תואמות למודל הייחוס, כולל מקרי קצה ו-CDC.

## שלב 4 - Basic Timer

מטרה: לממש מונה, compare, PWM ו-input capture לפי Figure 7 ו-Figure 8.

- [ ] לממש `BTCNT` ומקורות clock נבחרים.
- [ ] לממש `BTCTL1`: `BTINT`, `BTCLR`, `BTSSEL`, `BTHOLD`, `BTOUTEN`, `BTOUTMD`.
- [ ] לממש `BTCTL2`: `CAPISEL` ו-`CAPMD`.
- [ ] לממש compare registers וטעינת ערכי compare.
- [ ] לממש compare interrupt תקופתי.
- [ ] לממש PWM בשני מצבי output compare.
- [ ] לממש input capture ל-`BTCAPR` בקצה עולה ובקצה יורד.
- [ ] לסנכרן מקורות capture חיצוניים.
- [ ] לבדוק reset, hold, clear ושינוי clock source.
- [ ] ליצור testbench עצמאי לכל מצב לפני חיבור לפסיקות.

שער יציאה: timer period, PWM duty cycle ו-captured count תואמים לערכים הצפויים.

## שלב 5 - Pushbuttons

מטרה: להפוך את KEY1-KEY3 לקלט יציב ולמקורות פסיקה אמינים.

- [ ] להתאים לפולריות active-low של לחצני DE10-Standard.
- [ ] לסנכרן כל לחצן לשעון המערכת.
- [ ] לממש debounce לפי דרישת המסמך.
- [ ] לממש edge/event detection כך שלחיצה אחת יוצרת אירוע אחד.
- [ ] לממש קריאת `PORT_PB` בכתובת `0x2014`.
- [ ] להפיק flags נפרדים עבור KEY1, KEY2 ו-KEY3.
- [ ] לבדוק לחיצה קצרה, לחיצה ארוכה, bounce ולחיצות סמוכות.

שער יציאה: כל לחיצה חוקית נראית פעם אחת ב-MMIO ומייצרת flag יחיד.

## שלב 5.5 - בדיקת חומרה מוקדמת: Pushbuttons ו-PWM

מטרה: לאמת מוקדם על DE10-Standard את ממשקי הכרטיס, ה-reset, הכפתורים ויציאת
ה-PWM, לפני הוספת בקר הפסיקות ושינויי ה-CPU.

תנאי כניסה: שלבים 0–5 עברו את בדיקות ModelSim שלהם, ובפרט בדיקות ה-timer,
ה-PWM, הסנכרון וה-debounce.

- [ ] להשלים pin assignments רשמיים עבור `CLOCK_50`, `KEY`, `SW`, `LEDR`,
  `HEX` ופין ה-PWM הנבחר; אין להסתמך על הקצאת פינים אוטומטית.
- [ ] להוסיף יציאת PWM פיזית ל-Top-Level ולנתב אותה ל-LEDR או לפין GPIO
  מתאים למדידה.
- [ ] לחבר את KEY1-KEY3 ללוגיקת שלב 5, תוך שמירת KEY0 כ-reset active-low.
- [ ] להכין תוכנת או תצורת smoke-test שבה כל לחיצה חוקית משנה LED/HEX פעם
  אחת, והכפתורים משנים ערך duty cycle ניתן לצפייה.
- [ ] לבצע Quartus Full Compilation, לסקור warnings ולהפיק קובץ `.sof`.
- [ ] לצרוב את ה-SOF ולבדוק reset, לחיצה קצרה, לחיצה ארוכה, bounce ולחיצות
  סמוכות על הכרטיס.
- [ ] לבדוק PWM בכמה ערכי duty cycle; ב-LEDR לפי עוצמת הארה, ובמידת האפשר
  בפין GPIO באמצעות oscilloscope או logic analyzer.
- [ ] לשמור תמונות/מדידות ותוצאות הקומפילציה, וליצור checkpoint ב-Git.

בשלב זה הכפתורים נבדקים באמצעות polling או אות תצפית ייעודי. מסלול הפסיקה
המלא דרך Interrupt Controller ו-ISR ייבדק רק לאחר שלבים 6–7.

שער יציאה: כל KEY מייצר שינוי פיזי יחיד לכל לחיצה חוקית, ה-PWM נצפה בכמה
ערכי duty cycle, וה-SOF נטען ללא שגיאה. שלב זה אינו מחליף את בדיקת החומרה
המלאה ואת SignalTap בשלבים 9–10.

## שלב 6 - Interrupt Controller

מטרה: לרכז מקורות פסיקה, mask, flags, type ותעדוף.

- [ ] לממש את רגיסטרי `IE`, `IFG` ו-`TYPE`.
- [ ] לחבר `BTIFG` ואת flags של KEY1-KEY3.
- [ ] לשמור את ביטי UART שמורים או מנוטרלים כל עוד הבונוס אינו ממומש.
- [ ] לממש priority encoder לפי טבלת הווקטורים.
- [ ] להפיק `INTR` רק כאשר יש pending enabled interrupt ו-GIE פעיל.
- [ ] לממש `INTA`/service acknowledgement לפי הפרוטוקול.
- [ ] לממש clear אוטומטי או software clear לפי סוג המקור.
- [ ] לבדוק מקור יחיד, כמה מקורות יחד, mask ושינוי priority.

### תעדוף בסיסי ללא UART

| מקור | TYPE | עדיפות |
|---|---:|---:|
| RESET | `0x00` | 0, הגבוהה ביותר |
| Basic Timer | `0x10` | 4 |
| KEY1 | `0x14` | 5 |
| KEY2 | `0x18` | 6 |
| KEY3 | `0x1C` | 7, הנמוכה ביותר |

שער יציאה: `TYPE` תמיד מציג את המקור הפעיל בעל העדיפות הגבוהה, ו-flags מתנקים לפי הדרישה.

## שלב 7 - תמיכת פסיקות בתוך ה-CPU

מטרה: להוסיף לליבת single-cycle פרוטוקול פנימי רב-מחזורי בלי לשבור ביצוע רגיל.

- [ ] להגדיר GIE בביט `gp[0]` ואת התנהגות enable/disable.
- [ ] לממש FSM כניסה לפסיקה בשני מחזורים.
- [ ] במחזור הראשון: לנקות GIE, להפעיל `INTA` וללכוד `TYPE` מה-data bus.
- [ ] במחזור השני: לשמור `PC+4` ב-`tp` ולקפוץ דרך vector table.
- [ ] למנוע write-back, memory write או PC advance לא מכוונים בזמן ה-FSM.
- [ ] לזהות `jalr zero, 0(tp)` כ-`reti` ולהחזיר GIE ל-1.
- [ ] לבדוק שהחזרה היא בדיוק לפקודה שאחרי הפקודה שנקטעה.
- [ ] לבדוק פסיקה בזמן load, store, branch, jump, multiply ו-divider wait.

שער יציאה: ISR נכנס וחוזר באופן דטרמיניסטי, ללא איבוד או ביצוע כפול של פקודות.

## שלב 8 - אינטגרציה ואימות מלא

מטרה: להוכיח שהמערכת השלמה עובדת מול ה-golden model.

- [ ] ליצור `tb_RV32IMscMCU.vhd` מרכזי ובודק-עצמית.
- [ ] ליצור קובץ `.do` אחיד לקומפילציה, הרצה ו-waveforms.
- [ ] להריץ את כל ה-basic benchmarks.
- [ ] להריץ את כל ה-advanced/interrupt benchmarks.
- [ ] לדמות switches, pushbuttons, capture inputs ושעונים.
- [ ] להשוות DTCM סופי בין ModelSim לבין RARS.
- [ ] להוסיף assertions עבור illegal bus overlap, X/U, timeout ופרוטוקולי handshake.
- [ ] למדוד cycles ו-IPC בשיטה שתוגדר במפורש.
- [ ] לשמור waveforms מייצגים עבור הדוח.

שער יציאה: כל benchmark מסתיים ללא timeout או assertion failure, והזיכרון הסופי תואם ל-RARS.

## שלב 9 - Quartus ו-DE10-Standard

מטרה: להשלים את שלד Quartus שנוצר בשלב 1 ולהעביר את המימוש המאומת ל-FPGA.

- [ ] לעדכן את פרויקט Quartus של `RV32IMscMCU` בכל קובצי המימוש הסופיים.
- [ ] לבחור את רכיב ה-Cyclone V המדויק של DE10-Standard לפי קובץ הכרטיס.
- [ ] להגדיר את הישות המבנית העליונה כ-Top-Level Entity.
- [ ] להוסיף את כל קובצי ה-VHDL בסדר תקין.
- [ ] ליצור `.qsf` עם pin assignments עבור `CLOCK_50`, `KEY`, `SW`, `LEDR`, `HEX` ו-GPIO נדרש.
- [ ] ליצור/לעדכן `.sdc` עם clocks ו-clock constraints נכונים.
- [ ] להגדיר PLL ו-`DIVCLK` ולוודא clock relationships.
- [ ] לקמפל ללא errors ולסקור warnings משמעותיים.
- [ ] להפיק `.sof` ולבדוק reset, GPIO, timer ופסיקות על הכרטיס.

שער יציאה: ה-SOF נטען והמערכת מבצעת את תרחיש ההדגמה על DE10-Standard.

## שלב 10 - SignalTap ו-PPA

מטרה: לספק הוכחה על החומרה ולמלא את דרישות הניתוח.

- [ ] ליצור קובץ SignalTap `.stp` עם PC, instruction, bus, interrupt ו-timer signals.
- [ ] ללכוד תרחיש GPIO על הכרטיס.
- [ ] ללכוד כניסה ויציאה מפסיקה.
- [ ] ללכוד handshake של divider או timer לפי הצורך.
- [ ] להסיר final validation pins שאינם I/O אמיתי של ה-MCU.
- [ ] לשמור screenshot של Quartus Area report - חובה.
- [ ] לשמור screenshot של Quartus Fmax/Timing report - חובה.
- [ ] לזהות ולהסביר את ה-critical path.
- [ ] לשמור screenshot של Quartus Power report - חובה.
- [ ] למלא טבלאות Area, Performance ו-Power עבור MCU עם GPIO ועבור MCU עם פסיקות.
- [-] למלא שורת pipeline רק אם יבוצע הבונוס; אחרת לסמן N/A לאחר אימות מול המרצה.

שער יציאה: קיימות לכידות SignalTap ודוחות Quartus מלאים שניתן להכניס ישירות לדוח.

## שלב 11 - דוח והגשה

מטרה: להגיש חבילה נקייה, משתחזרת ותואמת למסמך.

- [ ] להכין Top-Level block diagram סופי.
- [ ] לצרף RTL Viewer results.
- [ ] לתאר בקצרה כל קובץ HDL.
- [ ] לצרף ניתוח waveforms של benchmarks בסיסיים ומתקדמים.
- [ ] לצרף טבלאות PPA וה-screenshots המחייבים.
- [ ] לתעד verification מול RARS ומדידת IPC.
- [ ] לכתוב מסקנות ומגבלות.
- [ ] ליצור `Readme.txt` שמסביר כל תיקייה ותת-תיקייה.
- [ ] לנקות קובצי build ותוצרים שאינם נדרשים.
- [ ] לוודא קומפילציה מחדש מתוך חבילת ההגשה הנקייה.
- [ ] ליצור `id1_id2.zip`, כאשר `id1 < id2`.
- [ ] לוודא שהסטודנט עם `id1` הוא שמעלה ל-Moodle.

### מבנה הגשה מתוכנן

```text
DUT/
  RV32IMscMCU/
TB/
  RV32IMscMCU/
SIM/
  RV32IMscMCU/
DOC/
Quartus/
  RV32IMscMCU/
```

תיקיות pipeline יתווספו רק אם הבונוס ימומש. חבילת העבודה יכולה להכיל קובצי `.qpf/.qsf`, אך לפני האריזה נוודא שוב מהם קובצי Quartus שהמסמך דורש בתוך ה-ZIP.

שער יציאה: ה-ZIP נפתח בתיקייה נקייה, ModelSim ו-Quartus מתקמפלים ממנו, והדוח מכיל את כל הראיות.

---

## מטריצת אימות

| רכיב | Unit TB | Integration TB | Benchmark/RARS | FPGA/SignalTap |
|---|---|---|---|---|
| RV32IM baseline | קיים חלקית | נדרש | RV32IM test1 | בהמשך |
| GPIO | נדרש | נדרש | GPIO test0-test2 | חובה |
| Divider | נדרש | נדרש | RV32IM/div tests | מומלץ |
| Basic Timer | נדרש | נדרש | interrupt tests | חובה |
| Pushbuttons | נדרש | נדרש | interrupt tests | חובה |
| Interrupt Controller | נדרש | נדרש | interrupt test1-test3 | חובה |
| CPU interrupt FSM | נדרש | נדרש | interrupt test1-test3 | חובה |

## סיכונים ונושאים שדורשים תשומת לב

1. כתובות MMIO מסוימות מופרדות בבית אחד, ולכן אסור לאבד את ביטי הכתובת הנמוכים.
2. ה-DTCM הקיים משתמש במיפוי word-oriented; צריך להפריד בין כתובת ה-bus לבין כתובת ה-RAM.
3. המחלק עובד בדומיין שעון אחר ודורש CDC ו-handshake ללא pulses אבודים.
4. כניסה לפסיקה היא רב-מחזורית בתוך ליבה שהייתה single-cycle.
5. reset ו-KEY ב-DE10-Standard הם active-low, בעוד testbenches קיימים משתמשים לעיתים ב-reset active-high.
6. קובצי הזיכרון בקוד המעבדה משתמשים בנתיבים מוחלטים ממחשב אחר.
7. מסמך הדרישות מפנה לחישוב IPC שאינו מופיע בצורה ברורה ב-PDF; נגדיר נוסחה ונאשר אותה לפני הדוח.
8. המסמך כותב "six subdirectories" אך מציג בטבלה חמש תיקיות ראשיות בלבד.
9. טבלת הפסיקות כוללת UART גם כאשר UART הוא בונוס; במימוש הבסיסי נשמור את המיקומים אך לא נפעילם.
10. יש אי-עקביות בשמות רגיסטרי compare של הטיימר (`BTCCRx/BTCLx` לעומת `BTCMPRx`); נמפה את השמות לפני המימוש.

## כללי עבודה ועדכון

1. לא משנים את תיקיות המקור: `מעבדה קודמת שלנו`, `קבצים מהמדריך` ו-`Benchmark apps`.
2. כל מימוש נעשה בעץ עבודה נפרד.
3. לא עוברים שלב לפני ששער היציאה של השלב הקודם עבר.
4. לכל רכיב חדש כותבים unit test לפני אינטגרציה.
5. כל כשל benchmark נרשם עם seed/input, cycle, PC ו-waveform רלוונטי.
6. אחרי כל milestone שומרים checkpoint ומעדכנים את מסמך המעקב.
7. בתחילת כל סשן עבודה נציג: שלב נוכחי, מה הושלם, מה הפעולה הבאה ומה חסום.
8. בונוסים לא מתחילים לפני ששלב 10 של מערכת החובה הושלם.

## הגדרת Done לפרויקט החובה

הפרויקט ייחשב גמור רק כאשר כל התנאים הבאים מתקיימים:

- כל שלבי 0-11 מסומנים `[x | timestamp]` או שסעיף שאינו רלוונטי מתועד במפורש.
- כל ה-benchmarks עוברים ב-ModelSim ותוצאת DTCM תואמת ל-RARS.
- ה-MCU פועל בפועל על DE10-Standard.
- קיימות לכידות SignalTap שמוכיחות GPIO ופסיקות.
- דוחות Area, Fmax ו-Power מלאים ומצורפים לדוח.
- חבילת ההגשה הנקייה מתקמפלת מחדש ללא תלות בנתיבים מקומיים.
