clear all; close all; tic; clc;
format long;

%% �������� ���������
% ��������� �� ��������  �����:
% 2020/02/25 13:45:18
Time_year = 2020;
Time_month = 2;
Time_day = 25;
Time_hour = 13;
Time_minutes = 45;
Time_seconds = 18;

% ���������� �� Te � ������� ��-90, [�]:
X = -8444572.27;
Y = -8664957.52;
Z = 22466454.10;

% ���������� ������� �������� �� Te � ������� ��-90, [�/�]:
VX = 2983.60348;
VY = -743.76965;
VZ =  832.83615;

% ��������� �����-��������� �� Te � ������� ��-90, [�/�2]:
AX = -0.0000028;
AY =  0.0000019;
AZ = -0.0000019;

% SV ��������� ��������, [��]:
Tau = -44762.2;
% SV ������������� �������� �������, [��/�]:
Gamma = 0.0009;

%% ������ ������� ������� �������
N4 = floor((Time_year-1996)/4) + 1; % ����� �������������� ���������
NT = 365*(Time_year-1996-4*(N4-1)) + 31 + Time_day + 1; % ����� ����� � ������������� ���������
tb = Time_seconds + Time_minutes*60 + Time_hour*60*60 + 10800; % ������� ����� � ��� [�]

% ������ �������� ��������� ������� �� ��������
GMST = GMST_calc( N4,NT );

%% �������� ��������� � ����������� ������� �������� ������ ���� ��� � ��������� � ������ ������� ��������� ��-90
% ������� ������� �������� �������� ����� ������������ ����� ��������� �������������, [���/�]:
Omega_E = 7.2921151467e-5;

Theta_Ge = GMST + Omega_E * (tb - 3 * 60 * 60);

% ����������:
X0 = X * cos(Theta_Ge) - Y * sin(Theta_Ge);
Y0 = X * sin(Theta_Ge) + Y * cos(Theta_Ge);
Z0 = Z;

% ��������:
VX0 = VX * cos(Theta_Ge) - VY * sin(Theta_Ge) - Omega_E * Y0;
VY0 = VX * sin(Theta_Ge) + VY * cos(Theta_Ge) + Omega_E * X0;
VZ0 = VZ;

% ���������:
JX0ms = AX * cos(Theta_Ge) - AY * sin(Theta_Ge);
JY0ms = AX * sin(Theta_Ge) + AY * cos(Theta_Ge);
JZ0ms = AZ;
        
%% �������������� ��������� �������
Toe = (12+3)*60*60;
Tof = (24+3)*60*60;
h = 1;

ti = Toe:h:Tof;

F0 = [X0 Y0 Z0 VX0 VY0 VZ0]; % ��������� �������

% [t, F] = ode45('diffs', tb:-Ts:ti(1), F0); % ����� �����-����� 4-�� �������
[t, F] = RungeKutta4( tb,-h,ti(1),F0 );
Fout = F(end:-1:2,:);
tout = t(end:-1:2,:);
% [t, F] = ode45('diffs', tb:Ts:ti(end), F0); % ����� �����-����� 4-�� �������
[t, F] = RungeKutta4( tb,h,ti(end),F0 );
Fout = [Fout; F];
tout = [tout; t];

th = hours(tout/60/60-3); % ������� ��������� ��� � ������ hh:mm:ss

%% ���� ���������
tau = tout - tb;
deltaX = JX0ms*(tau.^2)/2;
deltaY = JY0ms*(tau.^2)/2;
deltaZ = JZ0ms*(tau.^2)/2;

deltaVX = JX0ms*tau;
deltaVY = JY0ms*tau;
deltaVZ = JZ0ms*tau;

delta = [deltaX deltaY deltaZ deltaVX deltaVY deltaVZ];

Fout = Fout + delta;

%% ������ � ������ ��������
% ������ �� �����
FoutC = load('../source/data_out.txt'); 
% Fout = load('../source/Matlab_data_for_h01.txt'); 

% ������ � ����
data_out = fopen('../source/Matlab_test_data_out.txt', 'w+');     % �������� ����� �� ������
if data_out == -1                     % �������� ������������ ��������
    error('File is not opened');
end

F_out = [Fout(:,1), Fout(:,2), Fout(:,3)];
fprintf(data_out, '%.15f\n', F_out);   % ������ � ����
fclose(data_out);                % �������� �����

%% ������ ������� � ��
DeltaF1 = Fout - FoutC;
D_DeltaF1 = sqrt( DeltaF1(:,1).^2 + DeltaF1(:,2).^2 + DeltaF1(:,3).^2 );

figure
hold on
grid on
plot(th, D_DeltaF1, 'DurationTickFormat','hh:mm:ss')
%% �������� ��������� ������ ���� ��� � ������� ��������� ��-90
Theta_Ge = GMST + Omega_E * (tout - 3 * 60 * 60);

crd_PZ90(:,1) =  Fout(:,1).*cos(Theta_Ge) + Fout(:,2).*sin(Theta_Ge);
crd_PZ90(:,2) = -Fout(:,1).*sin(Theta_Ge) + Fout(:,2).*cos(Theta_Ge);
crd_PZ90(:,3) =  Fout(:,3);

%% �������� ��������� ������ ���� ��� � ������� ��������� WGS-84
ppb = 1e-9;
mas = 1e-3/206264.8; % [���]

MATRIX_WGS_84 = [-3*ppb -353*mas -4*mas;
                 353*mas -3*ppb 19*mas;
                 4*mas -19*mas -3*ppb];

crd_WGS_84 = crd_PZ90.'; % ������� � �������-�������

for i = 1:length(crd_WGS_84(1,:))
    crd_WGS_84(:,i) =  crd_WGS_84(:,i) + MATRIX_WGS_84 * crd_WGS_84(:,i) + [0.07; -0; -0.77];
end

crd_WGS_84 = crd_WGS_84.'; % ������� � �������-������

%% �������������� ���������� ������� � � �� ������� � ������� WGS-84
N_gr = 55;
N_min = 45;
N_sec = 24.1438;
N = N_gr*pi/180 + N_min/3437.747 + N_sec/206264.8; % ������ [���]

E_gr = 37;
E_min = 42;
E_sec = 11.3386;
E = E_gr*pi/180 + E_min/3437.747 + E_sec/206264.8; % ������� [���]

H = 500; % ������ [�]

llh = [N E H];
crd_PRM = llh2xyz(llh)';
 
 %% ����������� SkyPlot
for i = 1:length(crd_WGS_84(:,1))
    
    [X(i) Y(i) Z(i)] = ecef2enu(crd_WGS_84(i,1),crd_WGS_84(i,2),crd_WGS_84(i,3),N,E,H,wgs84Ellipsoid,'radians');
    if Z(i) > 0
        r(i) = sqrt(X(i)^2 + Y(i)^2 + Z(i)^2);
        teta(i) = acos(Z(i)/r(i));
        %teta(i) = atan2(sqrt(X(i)^2 + Y(i)^2),Z(i));
        %phi(i) = atan2(Y(i),X(i));
        if X(i) > 0
            phi(i) = -atan(Y(i)/X(i))+pi/2;
        elseif (X(i)<0)&&(Y(i)>0)
            phi(i) = -atan(Y(i)/X(i))+3*pi/2;
        elseif (X(i)<0)&&(Y(i)<0)
            phi(i) = -atan(Y(i)/X(i))-pi/2;
        end
    else teta(i) = NaN;
        r(i) = NaN;
        phi(i) = NaN;
    end
end

%% ���������� ��������
R_Earth = 6371e3;
[Xz,Yz,Zz] = sphere(30);

% ������������ �� � ��-90
figure
surf(Xz*R_Earth,Yz*R_Earth,Zz*R_Earth)
hold on
grid on
plot3(crd_PZ90(:,1), crd_PZ90(:,2), crd_PZ90(:,3), 'r')
plot3(Fout(:,1), Fout(:,2), Fout(:,3), 'b')
title('���������� �������� �������� ������� �5')
xlabel('��� �, �')
ylabel('��� Y, �')
zlabel('��� Z, �')
hold off
legend('�����','��-90', '������������ ��');

figure
surf(Xz*R_Earth,Yz*R_Earth,Zz*R_Earth)
hold on
grid on
plot3(Fout(:,1), Fout(:,2), Fout(:,3), 'b')
title('���������� �������� �������� ������� �5')
xlabel('��� �, �')
ylabel('��� Y, �')
zlabel('��� Z, �')
hold off

% �� ��-90
figure
surf(Xz*R_Earth,Yz*R_Earth,Zz*R_Earth)
hold on
grid on
plot3(crd_PZ90(:,1), crd_PZ90(:,2), crd_PZ90(:,3), 'b')
title({'���������� �������� �� �5 �������,' ; '� ������� ��������� ��-90'})
xlabel('��� �, �')
ylabel('��� Y, �')
zlabel('��� Z, �')
hold off

% �� WGS-84
figure
surf(Xz*R_Earth,Yz*R_Earth,Zz*R_Earth)
grid on
hold on
plot3(crd_WGS_84(:,1),crd_WGS_84(:,2),crd_WGS_84(:,3), 'b')
title({'���������� �������� �� �5 �������,' ; '� ������� ��������� WGS-84'})
xlabel('��� �, �')
ylabel('��� Y, �')
zlabel('��� Z, �')
hold off

% ��������
figure
ax = polaraxes;
polarplot(ax,phi,teta*180/pi)
ax.ThetaDir = 'clockwise';
ax.ThetaZeroLocation = 'top';
title('SkyView �������� ������� �5')

% ���� �����
figure
grid on
hold on
plot(th,(-teta)*180/pi+90,'DurationTickFormat','hh:mm:ss')
title('���� �����')
xlabel('����� � ���')
ylabel('���� �����, ����')
