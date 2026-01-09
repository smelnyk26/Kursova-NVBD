BACKUP DATABASE ProjectManagment
TO DISK = 'E:\7_sem\new_kursova\ProjectManagment_Final.bak'
WITH INIT, COMPRESSION, STATS = 10;



RESTORE VERIFYONLY
FROM DISK = 'E:\7_sem\new_kursova\ProjectManagment_Final.bak';
