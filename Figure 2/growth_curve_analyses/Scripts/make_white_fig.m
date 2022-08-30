function make_white_fig(fsize)%(fig,axs,legs,xlab,ylab,zlab)

fig=gcf;
axs=gca;
h = get(gcf,'children');
set(findall(fig,'-property','FontName'),'FontName', 'Arial')
set(findall(gcf,'-property','LineWidth'),'LineWidth',1)
for k = 1:length(h)
    if strcmpi(get(h(k),'type'),'axes')
        axs=h(k);
        ax1=get(axs,'position'); % Save the position as ax
        set(findobj(axs,'-property','FontSize'),'FontSize',fsize-5)
        xlab=get(axs,'xlabel');
        ylab=get(axs,'ylabel');
        zlab=get(axs,'zlabel');
        titles=get(axs,'title');
        set(axs,'Color',[1 1 1],'ZColor',[0 0 0],...
            'YColor',[0 0 0],...
            'XColor',[0 0 0],...
            'LineStyleOrderIndex',2,...
            'FontSize',fsize-5);
        box(axs,'on');
        % Create zlabel
        set(zlab,'FontSize',fsize);
        % Create ylabel
        set(ylab,'FontSize',fsize,'Color',[0 0 0]);
        % Create xlabel
        set(xlab,'FontSize',fsize);
        set(titles,'FontSize',fsize+1,'Color',[0 0 0]);
        set(findobj(axs,'Type','line','Color','w'),'Color','k')
        %         set(findobj(axs,'Type','Errorbar','Color','k'),'Color',[0.7 0.7 0.7])
        set(findobj(axs,'Type','Errorbar','Color','y'),'Color','b')
        set(findobj(axs,'Type','line','Color','y'),'Color','b')
        set(findobj(axs,'Type','line','Color','g'),'Color','b')
        set(axs,'LineWidth',1)
        set(axs,'position',ax1); % Manually setting this holds the position with colorbar
        set(axs,'LineWidth',0.5)
    end
    if strcmpi(get(h(k),'Tag'),'legend')
        legs = h(k);
        set(legs,'TextColor',[0 0 0],'FontSize',fsize-10,'color',[1 1 1]);
    end
end
set(fig,'Color',[1 1 1]);
set(fig,'Renderer','painters');
set(fig,'InvertHardCopy','off');


%http://www.mathworks.com/help/matlab/ref/findobj.html