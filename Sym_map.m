function [outbound] = Sym_map(inbound)
% Sym_map: Maps inbound symmetry values to outbound symmetry values.

inbound(inbound == 0)=(-1); 
inbound(inbound == 1)=+1;


outbound = inbound;

end

