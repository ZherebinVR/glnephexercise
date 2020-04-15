function dF = diffs( t, F )
J02 = 1082625.75e-9; % ��������� ������������� ����������� ������ �������, ��������������� �������� ������ �����
GM = 398600441.8e6; % ��������������� ��������� ��������������� ���� ����� � ������ ���������, [�3/c2]
a_e = 6378136; % ������� ������� ����������� ����������, [�]

crdX = F(1);
crdY = F(2);
crdZ = F(3);

r = sqrt(crdX^2 + crdY^2 + crdZ^2);

GM0 = GM / (r^2);
Rho = a_e / r;
crdX0 = crdX / r;
crdY0 = crdY / r;
crdZ0 = crdZ / r;

dF = F(:);
dF(1) = F(1);
dF(2) = F(2);
dF(3) = F(3);

dF(4) = - GM0 * crdX0 - 3/2 * J02 * GM0 * crdX0 * Rho^2 * (1 - 5 * crdZ0^2);
dF(5) = - GM0 * crdY0 - 3/2 * J02 * GM0 * crdY0 * Rho^2 * (1 - 5 * crdZ0^2);
dF(6) = - GM0 * crdZ0 - 3/2 * J02 * GM0 * crdZ0 * Rho^2 * (3 - 5 * crdZ0^2);
end