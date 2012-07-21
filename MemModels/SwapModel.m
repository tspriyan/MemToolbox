% SWAPMODEL returns a structure for a three-component model
% with guesses and swaps. Based on Bays, Catalao, & Husain (2009) model.
%
% Data struct should include:
%   data.errors: errors (radians), e.g., distance of response from target
%   data.distractors, Row 1: distance of distractor 1 from target
%   ...
%   data.distractors, Row N: distance of distractor N from target

function model = SwapModel()
  model.name = 'Swap model';
	model.paramNames = {'g', 'B', 'sd'};
	model.lowerbound = [0 0 0]; % Lower bounds for the parameters
	model.upperbound = [1 1 Inf]; % Upper bounds for the parameters
	model.movestd = [0.02, 0.02, 0.1];
  
  model.pdf = @SwapModelPDF;
  
	model.start = [0.2, 0.1, 10;  % g, B, K
    0.4, 0.1, 15;  % g, B, K
    0.1, 0.5, 20]; % g, B, K
  
  model.prior = @(p) JeffreysPriorForKappaOfVonMises(deg2k(p(3))); % SD
  
  model.priorForMC = @(p) (betapdf(p(1),1.25,2.5) * ... % for g
    betapdf(p(2),1.25,2.5) * ... % for B
    lognpdf(deg2k(p(3)),2,0.5)); % for sd
  
  model.pdfForPlot = @(data,g,B,sd)  ...
                        ((1-(g+B-g*B)).*vonmisespdf(data.errors(:),0,deg2k(sd)) + ...
                            (g+B-g*B).*unifpdf(data.errors(:),-180,180));
  model.generator = @SwapGenerator;
end

function p = SwapModelPDF(data, g, B, sd)
  % Parameter bounds check
  if g+B > 1
    p = zeros(size(data.errors));
    return;
  end
  
  % This could be vectorized entirely but would be less clear; but I assume
  % people will rarely have greater than 8 or so distractors, so the loop
  % is over a relatively small dimension
  nDistractors = size(data.distractors,1);
  p = (1-g-B).*vonmisespdf(data.errors(:),0,deg2k(sd)) + ...
          (g).*unifpdf(data.errors(:), -180, 180);
  for i=1:nDistractors
    p = p + (B/nDistractors).*vonmisespdf(data.errors(:),data.distractors(i,:)',deg2k(sd));
  end
end

function r = SwapGenerator(p, dims)
    model = StandardMixtureModelWithBiasSD();
    r = model.generator({0, p{1}+p{2}-p{1}*p{2}, p{3}}, dims);
end

