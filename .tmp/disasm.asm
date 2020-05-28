L0456:       equ  0456h
L047A:       equ  047Ah
L049E:       equ  049Eh
L064A:       equ  064Ah
L1130:       equ  1130h
L1203:       equ  1203h
L13A1:       equ  13A1h
L152B:       equ  152Bh
L16CD:       equ  16CDh
L1A97:       equ  1A97h
L23ED:       equ  23EDh
L2683:       equ  2683h
L2942:       equ  2942h
L5800:       equ  5800h
L6074:       equ  6074h
L608D:       equ  608Dh
L60D0:       equ  60D0h
L6124:       equ  6124h
L612F:       equ  612Fh


             org 0003h


0003 L0003:
0003 CD 24 00     CALL L0024  
0006 CD 03 12     CALL L1203  
0009 CD 74 11     CALL L1174  
000C CD A1 13     CALL L13A1  
000F CD 2B 15     CALL L152B  
0012 CD CD 16     CALL L16CD  
0015 CD 97 1A     CALL L1A97  
0018 CD ED 23     CALL L23ED  
001B CD 83 26     CALL L2683  
001E CD 42 29     CALL L2942  
0021 C3 03 00     JP   L0003  


0024 L0024:
0024 F3           DI          
0025 ED 91 52 0A  NEXTREG REG_MMU2,0Ah 
0029 CD 8D 60     CALL L608D  
002C FB           EI          
002D 76           HALT        
002E C5           PUSH BC     
002F 01 3B 24     LD   BC,243Bh 
0032 3E 2F        LD   A,2Fh  
0034 ED 79        OUT  (C),A  
0036 04           INC  B      
0037 ED 78        IN   A,(C)  
0039 ED 92 05     NEXTREG REG_PERIPHERAL_1,A 
003C C1           POP  BC     
003D F3           DI          
003E CD 74 60     CALL L6074  
0041 01 3B 12     LD   BC,123Bh 
0044 3E 00        LD   A,00h  
0046 ED 79        OUT  (C),A  
0048 11 0D EC     LD   DE,EC0Dh 
004B 3E 80        LD   A,80h  
004D 32 2F 61     LD   (L612F),A 
0050 CD 24 61     CALL L6124  
0053 11 0C 17     LD   DE,170Ch 
0056 3E 80        LD   A,80h  
0058 32 2F 61     LD   (L612F),A 
005B CD 24 61     CALL L6124  
005E 11 09 D8     LD   DE,D809h 
0061 3E 80        LD   A,80h  
0063 32 2F 61     LD   (L612F),A 
0066 CD 24 61     CALL L6124  
0069 11 06 E7     LD   DE,E706h 
006C 3E 80        LD   A,80h  
006E 32 2F 61     LD   (L612F),A 
0071 CD 24 61     CALL L6124  
0074 11 03 18     LD   DE,1803h 
0077 3E 80        LD   A,80h  
0079 32 2F 61     LD   (L612F),A 
007C CD 24 61     CALL L6124  
007F 11 04 03     LD   DE,0304h 


             org 02FCh


02FC L02FC:
02FC CD 30 11     CALL L1130  
02FF 21 00 D3     LD   HL,D300h 
0302 3E 32        LD   A,32h  
0304 CD 30 11     CALL L1130  
0307 21 00 D4     LD   HL,D400h 
030A 3E 33        LD   A,33h  
030C CD 30 11     CALL L1130  
030F 21 00 D5     LD   HL,D500h 
0312 3E 34        LD   A,34h  
0314 CD 30 11     CALL L1130  
0317 21 00 D6     LD   HL,D600h 
031A 3E 35        LD   A,35h  
031C CD 30 11     CALL L1130  
031F 21 00 D7     LD   HL,D700h 
0322 3E 36        LD   A,36h  
0324 CD 30 11     CALL L1130  
0327 21 00 D8     LD   HL,D800h 
032A 3E 37        LD   A,37h  
032C CD 30 11     CALL L1130  
032F 21 00 D9     LD   HL,D900h 
0332 3E 38        LD   A,38h  
0334 CD 30 11     CALL L1130  
0337 21 00 DA     LD   HL,DA00h 
033A 3E 39        LD   A,39h  
033C CD 30 11     CALL L1130  
033F 21 00 DB     LD   HL,DB00h 
0342 3E 3A        LD   A,3Ah  
0344 CD 30 11     CALL L1130  
0347 21 00 DC     LD   HL,DC00h 
034A 3E 3B        LD   A,3Bh  
034C CD 30 11     CALL L1130  
034F 21 00 DD     LD   HL,DD00h 
0352 3E 3C        LD   A,3Ch  
0354 CD 30 11     CALL L1130  
0357 21 00 DE     LD   HL,DE00h 
035A 3E 3D        LD   A,3Dh  
035C CD 30 11     CALL L1130  
035F 21 00 00     LD   HL,0000h 


             org 03DCh


03DC L03DC:
03DC CD E2 03     CALL L03E2  
03DF C3 DC 03     JP   L03DC  


03E2 L03E2:
03E2 3E 05        LD   A,05h  
03E4 3C           INC  A      
03E5 FE 0C        CP   0Ch    
03E7 DA EB 03     JP   C,L03EB 
03EA AF           XOR  A      
03EB L03EB:
03EB 32 E3 03     LD   (L03E2+1),A 
03EE E6 0E        AND  0Eh    
03F0 21 04 0F     LD   HL,0F04h 
03F3 ED 31        ADD  HL,A   
03F5 ED 91 43 80  NEXTREG REG_PALETTE_CONTROL,RPC_DISABLE_AUTOINC 
03F9 7E           LD   A,(HL) 
03FA 23           INC  HL     
03FB ED 92 40     NEXTREG REG_PALETTE_INDEX,A 
03FE 7E           LD   A,(HL) 
03FF 23           INC  HL     
0400 ED 92 41     NEXTREG REG_PALETTE_VALUE_8,A 
0403 46           LD   B,(HL) 
0404 23           INC  HL     
0405 7E           LD   A,(HL) 
0406 32 32 04     LD   (L0431+1),A 
0409 32 56 04     LD   (L0456),A 
040C 32 7A 04     LD   (L047A),A 
040F 32 9E 04     LD   (L049E),A 
0412 78           LD   A,B    
0413 ED 92 40     NEXTREG REG_PALETTE_INDEX,A 
0416 ED 91 41 FF  NEXTREG REG_PALETTE_VALUE_8,FFh 
041A F3           DI          
041B ED 91 56 2E  NEXTREG REG_MMU6,2Eh 
041F 3A 00 58     LD   A,(L5800) 
0422 CB 77        BIT  6,A    
0424 CA 29 04     JP   Z,L0429 
0427 C6 08        ADD  A,08h  
0429 L0429:
0429 E6 0F        AND  0Fh    
042B 21 48 C5     LD   HL,C548h 
042E ED 31        ADD  HL,A   
0430 7E           LD   A,(HL) 


0431 L0431:
0431 FE 18        CP   18h    
0433 C2 38 04     JP   NZ,L0438 
0436 3E FF        LD   A,FFh  
0438 L0438:
0438 57           LD   D,A    
0439 1E 80        LD   E,80h  
043B 3E A0        LD   A,A0h  
043D 32 2F 61     LD   (L612F),A 
0440 CD 24 61     CALL L6124  


             org 058Fh


058F L058F:
058F CD D0 60     CALL L60D0  
0592 3E 24        LD   A,24h  
0594 21 03 27     LD   HL,2703h 
0597 11 01 A4     LD   DE,A401h 
059A CD D0 60     CALL L60D0  
059D 3E 25        LD   A,25h  
059F 21 2D C9     LD   HL,C92Dh 
05A2 11 00 A5     LD   DE,A500h 
05A5 CD D0 60     CALL L60D0  
05A8 3E 26        LD   A,26h  
05AA 21 09 C3     LD   HL,C309h 
05AD 11 01 A6     LD   DE,A601h 
05B0 CD D0 60     CALL L60D0  
05B3 C3 4A 06     JP   L064A  


05B6 FE           defb FEh    
05B7 10           defb 10h    
05B8 C2           defb C2h    
05B9 EA           defb EAh    
05BA 05           defb 05h    
05BB 3E           defb 3Eh    
05BC 23           defb 23h    
05BD 21           defb 21h    
05BE 27           defb 27h    
05BF 2E           defb 2Eh    
05C0 11           defb 11h    
05C1 00           defb 00h    
05C2 A3           defb A3h    
05C3 CD           defb CDh    
05C4 D0           defb D0h    
05C5 60           defb 60h    
05C6 3E           defb 3Eh    
05C7 24           defb 24h    
05C8 21           defb 21h    
05C9 02           defb 02h    
05CA 27           defb 27h    
05CB 11           defb 11h    
05CC 01           defb 01h    
05CD A4           defb A4h    
05CE CD           defb CDh    
05CF D0           defb D0h    
05D0 60           defb 60h    
05D1 3E           defb 3Eh    
05D2 25           defb 25h    
05D3 21           defb 21h    
05D4 2E           defb 2Eh    
05D5 C9           defb C9h    
05D6 11           defb 11h    
05D7 00           defb 00h    
05D8 A5           defb A5h    
05D9 CD           defb CDh    
05DA D0           defb D0h    
05DB 60           defb 60h    
05DC 3E           defb 3Eh    
05DD 26           defb 26h    
05DE 21           defb 21h    
05DF 09           defb 09h    
05E0 C2           defb C2h    
05E1 11           defb 11h    
05E2 01           defb 01h    
05E3 A6           defb A6h    
05E4 CD           defb CDh    
05E5 D0           defb D0h    
05E6 60           defb 60h    
05E7 C3           defb C3h    
05E8 4A           defb 4Ah    
05E9 06           defb 06h    
05EA FE           defb FEh    
05EB 11           defb 11h    
05EC C2           defb C2h    
05ED 1E           defb 1Eh    
05EE 06           defb 06h    
05EF 3E           defb 3Eh    
05F0 23           defb 23h    
05F1 21           defb 21h    
05F2 27           defb 27h    


             org 0EF4h


0EF4 L0EF4:
0EF4 C5           defb C5h    
0EF5 01           defb 01h    
0EF6 3B           defb 3Bh    
0EF7 24           defb 24h    
0EF8 3E           defb 3Eh    
0EF9 2F           defb 2Fh    
0EFA ED           defb EDh    
0EFB 79           defb 79h    
0EFC 04           defb 04h    
0EFD ED           defb EDh    
0EFE 78           defb 78h    
0EFF ED           defb EDh    
0F00 92           defb 92h    
0F01 05           defb 05h    
0F02 C1           defb C1h    
0F03 C9           defb C9h    
0F04 09           defb 09h    
0F05 D8           defb D8h    
0F06 0A           defb 0Ah    
0F07 E8           defb E8h    
0F08 06           defb 06h    
0F09 E7           defb E7h    
0F0A 03           defb 03h    
0F0B 18           defb 18h    
0F0C 04           defb 04h    
0F0D 03           defb 03h    
0F0E 05           defb 05h    
0F0F C0           defb C0h    
0F10 09           defb 09h    
0F11 D8           defb D8h    
0F12 E5           defb E5h    
0F13 E6           defb E6h    
0F14 07           defb 07h    
0F15 21           defb 21h    
0F16 40           defb 40h    
0F17 C5           defb C5h    
0F18 85           defb 85h    
0F19 6F           defb 6Fh    
0F1A 8C           defb 8Ch    
0F1B 95           defb 95h    
0F1C 67           defb 67h    
0F1D 7E           defb 7Eh    
0F1E E1           defb E1h    
0F1F 77           defb 77h    
0F20 C9           defb C9h    
0F21 2D           defb 2Dh    
0F22 11           defb 11h    
0F23 60           defb 60h    
0F24 57           defb 57h    
0F25 60           defb 60h    
0F26 56           defb 56h    
0F27 60           defb 60h    
0F28 55           defb 55h    
0F29 60           defb 60h    
0F2A 54           defb 54h    
0F2B 60           defb 60h    
0F2C 53           defb 53h    
0F2D 60           defb 60h    
0F2E 52           defb 52h    
0F2F 60           defb 60h    
0F30 51           defb 51h    
0F31 60           defb 60h    
0F32 50           defb 50h    
0F33 40           defb 40h    
0F34 57           defb 57h    
0F35 40           defb 40h    
0F36 56           defb 56h    
0F37 40           defb 40h    
0F38 55           defb 55h    
0F39 40           defb 40h    
0F3A 54           defb 54h    
0F3B 40           defb 40h    
0F3C 53           defb 53h    
0F3D 40           defb 40h    
0F3E 52           defb 52h    
0F3F 40           defb 40h    
0F40 51           defb 51h    
0F41 40           defb 40h    
0F42 50           defb 50h    
0F43 20           defb 20h    
0F44 57           defb 57h    
0F45 20           defb 20h    
0F46 56           defb 56h    
0F47 20           defb 20h    
0F48 55           defb 55h    
0F49 20           defb 20h    
0F4A 54           defb 54h    
0F4B 20           defb 20h    
0F4C 53           defb 53h    
0F4D 20           defb 20h    
0F4E 52           defb 52h    
0F4F 20           defb 20h    
0F50 51           defb 51h    
0F51 20           defb 20h    
0F52 50           defb 50h    
0F53 00           defb 00h    
0F54 57           defb 57h    
0F55 00           defb 00h    
0F56 56           defb 56h    
0F57 00           defb 00h    


             org 1174h


1174 L1174:
1174 CD 8D 60     CALL L608D  
1177 CD 74 60     CALL L6074  
117A FB           EI          
117B 76           HALT        
117C C5           PUSH BC     
117D 01 3B 24     LD   BC,243Bh 
1180 3E 2F        LD   A,2Fh  
1182 ED 79        OUT  (C),A  
1184 04           INC  B      
1185 ED 78        IN   A,(C)  
1187 ED 92 05     NEXTREG REG_PERIPHERAL_1,A 
118A C1           POP  BC     
118B 11 0C 00     LD   DE,000Ch 
118E 3E 80        LD   A,80h  
1190 32 2F 61     LD   (L612F),A 
1193 CD 24 61     CALL L6124  
1196 11 0E 00     LD   DE,000Eh 
1199 3E 80        LD   A,80h  
119B 32 2F 61     LD   (L612F),A 
119E CD 24 61     CALL L6124  
11A1 11 0A 00     LD   DE,000Ah 
11A4 3E 80        LD   A,80h  
11A6 32 2F 61     LD   (L612F),A 
11A9 CD 24 61     CALL L6124  
11AC F3           DI          
11AD ED 91 57 1E  NEXTREG REG_MMU7,1Eh 
11B1 21 00 E0     LD   HL,E000h 
11B4 11 00 40     LD   DE,4000h 
11B7 01 00 1B     LD   BC,1B00h 
11BA ED B0        LDIR        
11BC F3           DI          
11BD ED 91 56 00  NEXTREG REG_MMU6,00h 
11C1 ED 91 57 01  NEXTREG REG_MMU7,01h 
11C5 FB           EI          
11C6 ED 91 15 17  NEXTREG REG_SPRITE_LAYER_SYSTEM,17h 
11CA 76           HALT        
11CB C5           PUSH BC     
11CC 01 3B 24     LD   BC,243Bh 
11CF 3E 2F        LD   A,2Fh  
11D1 ED 79        OUT  (C),A  
11D3 04           INC  B      
11D4 ED 78        IN   A,(C)  
11D6 ED 92 00     NEXTREG REG_MACHINE_ID,A 


             org 403Bh


403B L403B:
403B FC           defb FCh    
403C 00           defb 00h    
403D 7C           defb 7Ch    
403E 00           defb 00h    
403F 00           defb 00h    
4040 00           defb 00h    
4041 00           defb 00h    
4042 00           defb 00h    
4043 FF           defb FFh    
4044 FF           defb FFh    
4045 FC           defb FCh    
4046 00           defb 00h    
4047 FF           defb FFh    
4048 FF           defb FFh    
4049 FC           defb FCh    
404A 00           defb 00h    
404B FF           defb FFh    
404C FF           defb FFh    
404D FC           defb FCh    
404E 00           defb 00h    
404F FF           defb FFh    
4050 FF           defb FFh    
4051 FC           defb FCh    
4052 00           defb 00h    
4053 FF           defb FFh    
4054 FF           defb FFh    
4055 FC           defb FCh    
4056 00           defb 00h    
4057 FF           defb FFh    
4058 FF           defb FFh    
4059 FC           defb FCh    
405A 00           defb 00h    
405B FF           defb FFh    
405C FF           defb FFh    
405D FC           defb FCh    
405E 00           defb 00h    
405F 00           defb 00h    
4060 7F           defb 7Fh    
4061 FF           defb FFh    
4062 FE           defb FEh    
4063 00           defb 00h    
4064 00           defb 00h    
4065 00           defb 00h    
4066 00           defb 00h    
4067 00           defb 00h    
4068 00           defb 00h    
4069 00           defb 00h    
406A 00           defb 00h    
406B 00           defb 00h    
406C 00           defb 00h    
406D 00           defb 00h    
406E 00           defb 00h    
406F 00           defb 00h    
4070 00           defb 00h    
4071 00           defb 00h    
4072 00           defb 00h    
4073 00           defb 00h    
4074 00           defb 00h    
4075 00           defb 00h    
4076 00           defb 00h    
4077 00           defb 00h    
4078 00           defb 00h    
4079 00           defb 00h    
407A 00           defb 00h    
407B 00           defb 00h    
407C 00           defb 00h    
407D 01           defb 01h    
407E FF           defb FFh    
407F 80           defb 80h    
4080 7C           defb 7Ch    
4081 00           defb 00h    
4082 7E           defb 7Eh    
4083 00           defb 00h    
4084 00           defb 00h    
4085 00           defb 00h    
4086 00           defb 00h    
4087 00           defb 00h    
4088 00           defb 00h    
4089 00           defb 00h    
408A 00           defb 00h    
408B 00           defb 00h    
408C 00           defb 00h    
408D 00           defb 00h    
408E 00           defb 00h    
408F 00           defb 00h    
4090 00           defb 00h    
4091 00           defb 00h    
4092 00           defb 00h    
4093 00           defb 00h    
4094 00           defb 00h    
4095 00           defb 00h    
4096 00           defb 00h    
4097 00           defb 00h    
4098 00           defb 00h    
4099 00           defb 00h    
409A 00           defb 00h    
409B 00           defb 00h    
409C 00           defb 00h    
409D FC           defb FCh    
409E 00           defb 00h    
409F 00           defb 00h    


             org 52CAh


52CA L52CA:
52CA FC           defb FCh    
52CB FF           defb FFh    
52CC FF           defb FFh    
52CD 00           defb 00h    
52CE FC           defb FCh    
52CF FF           defb FFh    
52D0 FF           defb FFh    
52D1 00           defb 00h    
52D2 FC           defb FCh    
52D3 FF           defb FFh    
52D4 FF           defb FFh    
52D5 00           defb 00h    
52D6 FC           defb FCh    
52D7 FF           defb FFh    
52D8 FF           defb FFh    
52D9 00           defb 00h    
52DA FC           defb FCh    
52DB FF           defb FFh    
52DC FF           defb FFh    
52DD 00           defb 00h    
52DE 00           defb 00h    
52DF 00           defb 00h    
52E0 00           defb 00h    
52E1 00           defb 00h    
52E2 3F           defb 3Fh    
52E3 FF           defb FFh    
52E4 FC           defb FCh    
52E5 00           defb 00h    
52E6 3F           defb 3Fh    
52E7 FF           defb FFh    
52E8 FC           defb FCh    
52E9 00           defb 00h    
52EA 3F           defb 3Fh    
52EB FF           defb FFh    
52EC FC           defb FCh    
52ED 00           defb 00h    
52EE 3F           defb 3Fh    
52EF FF           defb FFh    
52F0 FC           defb FCh    
52F1 00           defb 00h    
52F2 3F           defb 3Fh    
52F3 FF           defb FFh    
52F4 FC           defb FCh    
52F5 00           defb 00h    
52F6 3F           defb 3Fh    
52F7 FF           defb FFh    
52F8 FC           defb FCh    
52F9 00           defb 00h    
52FA 3F           defb 3Fh    
52FB FF           defb FFh    
52FC FC           defb FCh    
52FD 00           defb 00h    
52FE 00           defb 00h    
52FF 00           defb 00h    
5300 1F           defb 1Fh    
5301 FF           defb FFh    
5302 F8           defb F8h    
5303 00           defb 00h    
5304 00           defb 00h    
5305 00           defb 00h    
5306 00           defb 00h    
5307 00           defb 00h    
5308 00           defb 00h    
5309 00           defb 00h    
530A 00           defb 00h    
530B 00           defb 00h    
530C 00           defb 00h    
530D 00           defb 00h    
530E 00           defb 00h    
530F 00           defb 00h    
5310 00           defb 00h    
5311 00           defb 00h    
5312 00           defb 00h    
5313 00           defb 00h    
5314 00           defb 00h    
5315 00           defb 00h    
5316 00           defb 00h    
5317 00           defb 00h    
5318 00           defb 00h    
5319 00           defb 00h    
531A 00           defb 00h    
531B 00           defb 00h    
531C 00           defb 00h    
531D FC           defb FCh    
531E 00           defb 00h    
531F 7F           defb 7Fh    
5320 00           defb 00h    
5321 00           defb 00h    
5322 00           defb 00h    
5323 00           defb 00h    
5324 00           defb 00h    
5325 00           defb 00h    
5326 00           defb 00h    
5327 00           defb 00h    
5328 00           defb 00h    
5329 00           defb 00h    
532A 00           defb 00h    
532B 00           defb 00h    
532C 00           defb 00h    
532D 00           defb 00h    


             org 8013h


8013 L8013:
8013 00           defb 00h    
8014 00           defb 00h    
8015 00           defb 00h    
8016 00           defb 00h    
8017 00           defb 00h    
8018 00           defb 00h    
8019 00           defb 00h    
801A 00           defb 00h    
801B 00           defb 00h    
801C 00           defb 00h    
801D 00           defb 00h    
801E 00           defb 00h    
801F 00           defb 00h    
8020 00           defb 00h    
8021 00           defb 00h    
8022 00           defb 00h    
8023 00           defb 00h    
8024 00           defb 00h    
8025 00           defb 00h    
8026 00           defb 00h    
8027 00           defb 00h    
8028 00           defb 00h    
8029 00           defb 00h    
802A 00           defb 00h    