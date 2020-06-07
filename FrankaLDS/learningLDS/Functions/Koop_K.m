function [A, G] = Koop_K(x1, x2, u)
A = Psi_x(x2,u)*Psi_x(x1, u)';
G = Psi_x(x1,u)*Psi_x(x1, u)';
end