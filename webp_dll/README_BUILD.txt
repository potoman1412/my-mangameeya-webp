สรุปการทำงาน

ไฟล์นี้เป็นตัวอย่างซอร์สโค้ดสำหรับสร้าง `webp.all` (DLL ที่มีนามสกุล .all) ที่ให้ความสามารถแปลง/ถอดรหัสไฟล์ .webp เป็นภาพแบบที่แอปอ่านได้ (เช่น PNG/BMP) โดยใช้ไลบรารี Google libwebp

ข้อจำกัดสำคัญ
- ผมไม่มีข้อมูล API/exports ของ `jpg.dll` หรือ `png.dll` ที่โปรแกรม MangaMeeya CE คาดหวังไว้ ดังนั้นโค้ดตัวอย่างนี้จะให้ฟังก์ชัน C API ทั่วไป (`DecodeWebPToPNG`) ซึ่งอาจจะต้องปรับให้ตรงกับอินเทอร์เฟซของแอปจริงก่อนจะเป็น "drop-in" แทน `jpg.dll`/`png.dll`
- การคอมไพล์ต้องมี Visual Studio (Developer Command Prompt) และไลบรารี `libwebp` พร้อมไฟล์ header + .lib

ไฟล์ที่รวมไว้
- `webp_dll.cpp` : ซอร์ส C++ ตัวอย่างที่ส่งออกฟังก์ชัน `DecodeWebPToPNG`
- `build_instructions.txt` : ขั้นตอนคอมไพล์บน Windows (Visual Studio)

วิธีคอมไพล์ (สรุป)
1. ดาวน์โหลดและคอมไพล์หรือดาวน์โหลดไบนารี `libwebp` สำหรับ Windows (headers + .lib)
   - http://developers.google.com/speed/webp/download
2. เปิด "Developer Command Prompt for VS"
3. ไปที่โฟลเดอร์ `webp_dll`
4. รันคำสั่ง (ปรับพาธ `INCLUDE`/`LIB` ให้ชี้ไปยัง libwebp):

cl /EHsc /LD webp_dll.cpp /I"C:\path\to\libwebp\include" /link /LIBPATH:"C:\path\to\libwebp\lib" webp.lib /OUT:webp.all

(คำสั่งข้างต้นสมมติไลบรารีชื่อ `webp.lib`; ปรับชื่อตามที่ได้)

การใช้งานหลังคอมไพล์
-- จะได้ไฟล์ `webp.all` (เป็น DLL แต่มีนามสกุล .all) ซึ่งมีฟังก์ชันที่ช่วยแปลงไฟล์ .webp เป็น .png
- หากต้องการให้โปรแกรม MangaMeeya CE โหลดอัตโนมัติเป็น plugin แทน `jpg.dll`/`png.dll` คุณอาจต้องแกะ (reverse-engineer) หรือหา API/exports ที่แอปเรียกใช้ แล้วปรับฟังก์ชันให้ตรง

ต้องการให้ผม:
- สร้างซอร์สตัวอย่างแบบนี้ต่อ (ผมทำให้แล้ว) และช่วยเตรียมไฟล์ Visual Studio project เพื่อคอมไพล์ด้วย? (ผมสามารถสร้างไฟล์ .vcxproj แต่ผมไม่สามารถคอมไพล์ไบนารีที่นี่)
- หรือให้ผมพยายาม "สแกน" `jpg.dll`/`png.dll` เพื่อเดา exports และพยายามทำให้เป็น drop-in (งานนี้อาจไม่แม่นและเสี่ยงต่อข้อผิดพลาด)

บอกผมว่าต้องการขั้นต่อไปแบบไหนครับ (สร้าง .vcxproj, พยายามหาจุดเชื่อมต่อของโปรแกรม, หรือแค่ซอร์สและคำสั่งคอมไพล์)

การทดสอบ (local)
1. หลังคอมไพล์ `webp.all` ให้วางไฟล์ `webp.all` ไว้ในโฟลเดอร์ `webp_dll` หรือเดียวกับ `test_app.exe` ที่จะคอมไพล์
2. คอมไพล์โปรแกรมทดสอบ (เปิด Developer Command Prompt):

```
cl /EHsc test_app.cpp
```

3. รันทดสอบกับไฟล์ `.webp` ตัวอย่าง:

```
test_app.exe C:\path\to\sample.webp
```

โปรแกรมทดสอบจะโหลด `webp.all` และเรียก `LoadPicture` ที่ export จาก DLL; ผลลัพธ์จะแสดงรหัสการคืนค่าที่ช่วยหา bug ได้

หมายเหตุ: ถ้าคุณต้องการให้ `webp.dll` อยู่ในเส้นทางเดียวกับ `MMCE_Win32.exe` เพื่อให้โปรแกรมโหลดเอง ให้วาง `webp.dll` ในโฟลเดอร์เดียวกับ `MMCE_Win32.exe` และอย่าลืมเก็บ `png.dll` ต้นฉบับไว้เป็น `png_orig.dll` ถ้าต้องการหลีกเลี่ยงการชนกัน
