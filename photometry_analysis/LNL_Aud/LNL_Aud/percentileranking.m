function RTpr = percentileranking(a,t)
b = a(~isnan(a)); % ignore NaNs
    if ~isempty(b)
        L = length(find(cellfun(@(x) x(1), b) < t));
        E = length(find(cellfun(@(x) x(1), b) == t));
        N = length(b);
        RTpr = (L + 0.5 * E) / N * 100;
    else
        RTpr = NaN;
    end
end
