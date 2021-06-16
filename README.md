# Train-test split in R, with maximum representativity across all features.
Split an R data frame into train_X, test_X, train_y, and test_y sets. Optimize representativity of samples across features.

## Objective
I want to get a random sample of an R data frame in which each variable, in both the training and testing sets, is relatively representative of the superset.

I have seen ways to create a stratified sample based on a single variable. But, I want to ensure representation on multiple columns and not just factors.

## Attempt herein
Toward this end, I wrote a simple algorithm using the Wilcoxon test on each numeric variable. The assumption is that you probably have a fairly representative sample if all numeric columns in the sample (test set) seem to come from the same set as the numeric columns in the remaining set (train set). You take a random sample (train_test_split()) and validate it (validate_split()) by applying the Wilcoxon rank sum test to each variable. If any single variable doesn't pass the test, resample and validate. Repeat until you get a sample that meets your minimum representativity (as measured by alpha) across all variables.

In this case, because alpha represents the risk of incorrectly rejecting the null hypothesis (H0 = The samples did not come from significantly different populations, i.e. each side of the split is probably representative of the superset.), and because we want to fail to reject the null hypothesis, we want a p-value greater than alpha rather than less than alpha, and we want the greatest alpha that we can muster.

### Drawbacks
Again, this leaves out factors and integers entirely, unless you cast them as doubles, but that would violate the Wilcoxon assumption that the data is continuous.

Given that [my current dataset](https://www.kaggle.com/c/house-prices-advanced-regression-techniques/data) contains about 80 variables, a good portion of which are doubles, this suffices for now because I assume the factors are probably pretty representative if all the doubles are. But, it can take a long time (possibly forever) to run and get even p > .5 on all variables. And, what about a data set with all or most of its variables as factors or integers?

Is there a better way, both/either from a mathematical/statistical perspective and/or an R/programming perspective? Also, is this somehow problematic for machine learning? I'd like to think that it would improve the generalizability of the trained/tuned model, reduce the chance of overfit, but does it somehow create leakage or something else problematic?

#### Tracking p-values
In the current implementation, I record the p-values of each variable on each run and find the mean of them at the end. This allows you to run a quick split with a low alpha and check the average p-values for each feature to help determine a reasonable alpha for the set and which features might be worth dropping from the validation.

As a commenter on [Stack Overflow](https://stackoverflow.com/questions/67995221/how-to-sample-r-dataframe-so-that-its-representative-across-multiple-variables) pointed out, this grows vectors to possibly an unmanageable size.

You could write in a parameter and logic to switch this task on an off. It's a simple fix, but not implemented here.

## References
@Manual{,
  title = {R: A Language and Environment for Statistical Computing},
  author = {{R Core Team}},
  organization = {R Foundation for Statistical Computing},
  address = {Vienna, Austria},
  year = {2020},
  url = {https://www.R-project.org/},
}

@Article{,
  title = {Welcome to the {tidyverse}},
  author = {Hadley Wickham and Mara Averick and Jennifer Bryan and Winston Chang and Lucy D'Agostino McGowan and Romain François and Garrett Grolemund and Alex Hayes and Lionel Henry and Jim Hester and Max Kuhn and Thomas Lin Pedersen and Evan Miller and Stephan Milton Bache and Kirill Müller and Jeroen Ooms and David Robinson and Dana Paige Seidel and Vitalie Spinu and Kohske Takahashi and Davis Vaughan and Claus Wilke and Kara Woo and Hiroaki Yutani},
  year = {2019},
  journal = {Journal of Open Source Software},
  volume = {4},
  number = {43},
  pages = {1686},
  doi = {10.21105/joss.01686},
}

