%PLOTMODELPARAMETERSANDDATA plots the parameters of the model in a parallel coordinates plot. 
% It then shows you the fit of the model at each set of 
% parameter values, which you can see plotted by clicking on the parallel
% coordinates plot.
%
function figHand = PlotModelParametersAndData(model, posteriorSamples, data, varargin)
  % Plot data fit
  args = struct('PdfColor', [0.54, 0.61, 0.06], 'NumSamplesToPlot', 63, 'NewFigure', true); 
  args = parseargs(varargin, args);
  if args.NewFigure, figHand = figure(); end
  
  startCol = args.PdfColor;
  
  % Which to use
  which = round(linspace(1, size(posteriorSamples.vals,1), args.NumSamplesToPlot));
  [mapLikeVal,mapVal] = max(posteriorSamples.like);
  params = posteriorSamples.vals(mapVal,:);
  
  % Add MAP value to the end
  which = [which mapVal];
  
  % Setup to normalize them to same axis
  values = posteriorSamples.vals(which,:);
  [tmp,order]=sort(values(:,1));
  minVals = min(values);
  maxVals = max(values);
  
  % Parallel coordinates
  h=subplot(1,2,1);
  pos = get(h, 'Position');
  set(h, 'Position', [pos(1)-0.05 pos(2)+0.03 pos(3:end)]);
  for i=1:length(which)
    valuesNormalized(i,:) = (values(i,:) - minVals) ./ (maxVals - minVals);
    
    % Desaturate if not MAP
    colorOfLine(i,:) = fade(startCol, ...
      exp(posteriorSamples.like(which(i)) - mapLikeVal));
    
    seriesInfo(i) = plot(1:size(values,2), valuesNormalized(i,:), ... 
                         'Color', colorOfLine(i,:), 'LineSmoothing', 'on');
    
    % Special case of only one parameter
    if size(values,2) == 1
      seriesInfo(i) = plot(1:size(values,2), ...
        valuesNormalized(i,:), 'x', 'MarkerSize', 15, ...
        'Color', colorOfLine(i,:));
    end
    hold on;
  end
  set(gca, 'box', 'off');
  set(seriesInfo(end), 'LineWidth', 4); % Last one plotted is MAP value
  lastClicked = seriesInfo(end);
  set(gca, 'XTick', []);
  set(gca, 'XTickLabel', []);
  
  labelPos = [-0.03 1.02];
  set(gca, 'YTick', labelPos);
  set(gca, 'YTickLabel', {});
  set(gca, 'FontWeight', 'bold');
  %set(gca, 'YGrid','on')
  for i=1:length(minVals)
    line([i i], [0 1], 'LineStyle', '-', 'Color', 'k');
    for j=1:length(labelPos)
      txt = sprintf('%0.3f', minVals(i)+(maxVals(i)-minVals(i)).*labelPos(j));
      text(i-0.03, labelPos(j), txt, 'FontWeight', 'bold', 'FontSize', 10);
    end
    text(i-0.03, -0.10, model.paramNames{i}, 'FontWeight', 'bold', 'FontSize', 12);
  end
  
  set(gca,'ButtonDownFcn', @Click_Callback);
  set(get(gca,'Children'),'ButtonDownFcn', @Click_Callback);
  line([1.001 1.001], [0 1], 'Color', [0 0 0]);
  %line([1 length(model.paramNames)], [0.001 0.001], 'Color', [0 0 0]);
  
  % Plot data histogram
  h=subplot(1,2,2);
  pos = get(h, 'Position');
  set(h, 'Position', [pos(1) pos(2)+0.03 pos(3:end)]);
  PlotModelFit(model, params, data, 'PdfColor', colorOfLine(end,:));
  line([-179.99 -179.99], [0 max(ylim)], 'Color', [0 0 0]);
  line([-180 180], [0.0001 0.0001], 'Color', [0 0 0]);
  
  % What to do when series is clicked
  function Click_Callback(tmp,tmp2)
    % Get the point that was clicked on
    cP = get(gca,'Currentpoint');
    cx = cP(1,1); 
    cy = cP(1,2);
    
    % Show that series
    diffValues = (cy-interp1(1:size(posteriorSamples.vals,2), ...
      valuesNormalized', cx)).^2;
    [tmp,minValue] = min(diffValues);
    set(seriesInfo(minValue), 'LineWidth', 4);
    set(seriesInfo(minValue), 'Color', colorOfLine(minValue,:));
    uistack(seriesInfo(minValue), 'top');
    % Unhighlight old series
    if lastClicked ~= seriesInfo(minValue)
      set(lastClicked, 'LineWidth', 1);
    end
    lastClicked = seriesInfo(minValue);
    drawnow;
    
    subplot(1,2,2); hold off;
    PlotModelFit(model, values(minValue,:), data, ...
                 'PdfColor', colorOfLine(minValue,:));
    line([-179.99 -179.99], [0 max(ylim)], 'Color', [0 0 0]);
    line([-180 180], [0.0001 0.0001], 'Color', [0 0 0]);

  end
end

