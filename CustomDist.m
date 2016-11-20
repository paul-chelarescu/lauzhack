function [dist] = CustomDist(X, Y)

differences = (X - Y) .^ 2;

meandif = sum(differences) / size(differences, 1);

dist = sum((meandif * ones(size(differences, 1)) - differences) .^ 2) / size(differences, 1);