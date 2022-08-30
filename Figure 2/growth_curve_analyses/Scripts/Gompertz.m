function [lag,rate,OD_max,OD_i] = Gompertz(time,OD)
plot_yes = 1;
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
if plot_yes
    figure(100);
%     subplot(1,3,1)
%     plot(time,log(OD/OD(1)),time,log(f(p,time)/f(p,time(1))))
%     ylabel('log(OD/OD_i)','FontSize',12)
%     xlabel('Time','FontSize',12)
%     subplot(1,3,2)
    plot(time,OD,'.',time,f(p,time))
    ylabel('OD','FontSize',12)
    xlabel('Time','FontSize',12)
%     subplot(1,3,3)
    plot(time,exp(OD),'.',time,exp(f(p,time)))
%     ylabel('OD','FontSize',12)
%     xlabel('Time','FontSize',12)  
    title(['rate=' num2str(rate,2) ' lag=' num2str(lag) ' maxOD=' num2str(OD_max)])

    make_white_fig(25)

    h = legend('Data','Gompertz fit');
    set(h,'Interpreter','none',...
        'FontSize',12)
    box on
end
