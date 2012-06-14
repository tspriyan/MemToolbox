function model = EnsureAllModelMethods(model)
  % If no prior, just put a uniform prior on all parameters
  if ~isfield(model, 'prior')
    model.prior = @(params)(1);
  end
  
  % if no logpdf, create one from pdf
  if ~isfield(model, 'logpdf')
    model.logpdf = @(varargin)(sum(log(model.pdf(varargin{:}))));
  end
  
  % If there's no model.pdf, create one using model.logpdf
  if ~isfield(model, 'pdf')
    model.pdf = @(varargin)(exp(model.logpdf(varargin{:})));
  end
end