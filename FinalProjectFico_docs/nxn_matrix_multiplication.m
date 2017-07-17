clear all; clc; close all;
n=10; % nxn, n value of matrix
x=0; y=1;
for i=1:n 
	for j=1:n
		if mod(j, 2) == 0 	% j is even
			A(i,j)=0;
			B(i,j)=0;
        else                % j is odd
			A(i,j)=x;
			x=x+2;
			B(i,j)=y;
			y=y+2;
		end		
	end
end
A
B
C=A*B
