function psi = Psi_x(s, u)

s = double(s); u = double(u);

s = s(:);
u = u(:);

% States

psi = [s(1:3); s(7:end); u]; 
% psi = [s(1:3); s(7:end); 1;u]; 

% psi = [s; 1; u];
% psi = [s; u];


psi = double(psi);


end