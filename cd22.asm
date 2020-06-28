;程序功能：输出小于等于输入三位数的水仙花数

data segment
	;提示字符串
	inputsign db 0dh,0ah,'Please input a number(100<=100<=999):$'
	inputerror db 0dh,0ah,'Input error,please input again!$'
	inputcontinue db 0dh,0ah,'Do you want to continue(y/n)?  $'
	shuixianhua db 0dh,0ah,'shuixianhuashu:$'
	lastsign db 0dh,0ah,0dh,0ah,'           Press any key to continue',0dh,0ah,'$'
	nohua db 'None$'
	
	inputstr db 5				;存放输入数字（字符串格式）
			 db ?
			 db 5 dup(?)
	mulbit db 100,10,1			;用于计算立方和的乘数
	num dw ?					;存放转换后的数字
	shuixianhuashu db 10 dup(?)	;存放水仙花数（字符串格式）
data ends

stack segment
	dw 200 dup(?)
stack ends

code segment
	assume ds:data,ss:stack,cs:code
	
output macro strname
	;;功能：输出字符串宏定义
	;;参数：strname：输出字符串偏移地址
		lea dx,strname
		mov ah,9
		int 21h
	endm

jcc macro cc,a,b,dest
	;;功能：条件跳转宏定义
	;;参数：cc：jcc指令的具体后缀，a、b：比较的两个参数，dest：跳转到的标号
		cmp a,b
		j&cc dest
	endm
	
start:
		mov ax,data
		mov	ds,ax
		mov ax,stack
		mov	ss,ax
	
	input:
		output inputsign		;输出输入数字提示
		
		lea dx,inputstr			;输入数字（字符串格式）
		mov ah,10
		int 21h
		
		jcc nz,inputstr+1,3,inputagain
								;先比较输入的位数是否满足
		lea si,inputstr+2
		lea di,num
		lea bx,mulbit
		mov cl,inputstr+1
		call strtonum			;将输入数字由字符串转换为数字
		jcc z,bx,0,inputagain	;若strtonum返回值为0失败，则重新输入
		
		output shuixianhua		;输出水仙花标题
		call findnum			;寻找水仙花数，并输出
		
	continue:
		output inputcontinue	;输入是否继续提示？
		
		mov ah,1
		int 21h					;输入字符
		
		jcc z,al,'y',input
		jcc z,al,'Y',input		;则跳转到input重新开始
		
		jcc z,al,'n',ending
		jcc z,al,'N',ending		;则跳转到ending程序结束
	
		output inputerror		;若输入其他字符，则提示输入错误，重新输入

		jmp continue			;跳转到continue重新判断是否继续
	
	ending:
		output lastsign			;输出最后的press any key....
		
		mov ah,1				;接受任意字符后结束程序
		int 21h
		
		mov ax,4c00h
		int 21h
			
	inputagain:
		output inputerror		;输入错误，重新输入
		jmp input
	

strtonum proc
	;功能：将数字字符串转换为数字,同时判断是否介于100和999之间
	;参数：si源字符串偏移地址，di为目的数储存位置,bx为乘数因子位置，cx为数字位数
	;返回值：bx为1表示成功，为0表示失败，[di]所存为最终数字
	;dx做最终数字，al做乘法乘数，cl循环记数
		push ax
		push cx
		push dx
		push si
		
		mov dx,0
		mov byte ptr [di],0
	bittonum:
		mov al,[si]				;将每个字符移至al
		sub al,30h				;将字符转换成数字
		jcc l,al,0,numerror
		jcc g,al,9,numerror		;字符不在0~9之间则返回0失败
		mul	byte ptr [bx]		;al*[bx]即数字变为真实数值
		add dx,ax				;加到最后的数字上
		inc bx
		inc si
		loop bittonum
		
		jcc l,dx,100,numerror	;比较最终数字小于100则返回0失败
		mov [di],dx				;将最终数字移至[di]
		mov bx,1				;返回1成功
		jmp exit		
	numerror:
		mov bx,0
	exit:
		pop si
		pop dx
		pop cx
		pop ax
		ret
strtonum endp		
		
		
dtoc proc
	;功能：将word型数据转变为表示十进制数的字符串，字符串以 $为结尾符，并显示
	;参数：(ax)=word型数据，ds:si指向字符串首地址
	;返回：无
		push ax
		push bx
		push cx
		push dx
		push si					;主程序寄存器数据入栈保护
		
		mov bx,10				;10做除数存到bx中
		mov cx,0				;cx做计数器记位 置零
	getc:
		mov dx,0				;将dx清零 为除法做准备
		div bx					;(dx,ax)除以bx
		add dx,30h				;余数dx为对应十进制数，+30h转换为ASCII码
		push dx					;将余数入栈存储
		inc cx					;位数+1
		
		jcc z,ax,0,putc			;若商为0跳转到putc
		
		jmp getc				;商不为0跳转到getc
	putc:
		pop [si]				;将栈中字符出栈存入[si]指向的内存
		inc si					;si指向下一字符
		loop putc
		mov byte ptr [si],' '
		mov byte ptr [si+1],'$'	;添加结束符
		
		pop si
		
		mov dx,si				;输出数字对应的字符
		mov ah,9
		int 21h
		
		pop dx
		pop cx
		pop bx
		pop ax					;主程序寄存器数据出栈恢复
		ret
dtoc endp
		
		
findnum proc
	;功能：寻找水仙花数，并输出
	;参数：
	;ax做增量，cx记录个数,bx做除数,dx用来记录和
		push ax
		push bx
		push cx
		push dx
		push si
		
		mov ax,100				;从100开始遍历
		mov bl,10				;（bl）=10做除数
		mov cx,0				;cx来记录水仙花数的个数
	loops:						;总循环
		push ax					;将当前判断数入栈保护
		push cx					;将cx记录的个数入栈保护
	getbit:						;获取每一位的数字并入栈
		div bl					;当前判断数除以10，ah为余数，al为商
		mov cl,ah				;余数入栈保护
		mov ch,0
		push cx
		mov ah,0				;ah补0
		jcc nz,ax,0,getbit		;比较商是否为0不为0继续getbit
								;商为0后
		mov cx,3				;将cx赋值为3
		mov dx,0				;将和dx初始化为0
	addnum:						;每一位立方和求和
		pop ax					;余数出栈到ax，实际ah总为0
		mov bh,al				;此处须将al先复制到bh中储存
		mul bh
		mul bh					;ax=bh*bh*bh 
		add dx,ax				;将每一位的立方ax加到dx中
		loop addnum
		
		pop cx					;将cx记录的个数出栈恢复
		pop ax					;将ax记录的当前判断数出栈恢复
		jcc nz,ax,dx,last		;比较ax和dx若不相等跳至last
		lea si,shuixianhuashu
		call dtoc				;若相等，输出水仙花数
		inc cx					;水仙花数个数+1
	last:						;循环变量增加
		inc ax					;当前判断数+1
		jcc le,ax,num,loops		;比较当前判断数和num 若ax<=num，继续循环
		
		jcc nz,cx,0,return 		;比较循环之后cx中记录的水仙花数
								;若水仙花数不为0，跳转到return
		
		output nohua			;若水仙花数为0，则输出没有
	return:
		pop si
		pop dx
		pop cx
		pop bx
		pop ax
		ret	
findnum endp

code ends

end start		
		
		
	
		