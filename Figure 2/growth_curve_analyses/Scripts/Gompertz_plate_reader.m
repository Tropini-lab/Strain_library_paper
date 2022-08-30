function [lag,rate,OD_max,OD_i] = Gompertz_plate_reader(time,OD)
f = @(p,time) (p(3)*exp(-exp(p(2)*exp(1).*(p(1)-time)/p(3)+1)))+p(4);
opts = statset('nlinfit');
opts.MaxIter = 10000;
opts.RobustWgtFun = 'fair';
% p = nlinfit(time,OD,f,[0.1 1/max(time) max(OD) min(OD)],opts);
lb = [0 0 0 0];
ub = [max(time) 10^3 max(OD)*1.2 max(OD)];
p = lsqcurvefit(f,[0.1 1/max(time) max(OD) min(OD)],time,OD,lb,ub);

lag = p(1);
rate = p(2);
OD_max = p(3);
OD_i = p(4);
figure(1);

hold on
plot(time,OD,'.',time,f(p,time))
ylabel('OD','FontSize',12)
xlabel('Time','FontSize',12)
hold off
title(['rate=' num2str(rate,2) ' lag=' num2str(lag,2) ' maxOD=' num2str(OD_max+OD_i,2)])%need to add OD_max to OD_i to get the apparent OD max

make_white_fig(25)

h = legend('Data','Gompertz fit');
set(h,'Interpreter','none',...
    'FontSize',12)
box on
