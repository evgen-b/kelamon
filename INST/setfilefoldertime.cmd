CD %1
"%nircmd%" setfilefoldertime *.* %ttii% %ttii% %ttii%
FOR /D %%i IN (*) DO CALL %0 "%%i"
CD ..

