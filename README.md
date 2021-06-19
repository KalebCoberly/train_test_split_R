# Train-test split in R, with maximum representativity across all features.
Split an R data frame into train_X, test_X, train_y, and test_y sets. Optimize representativity of samples across features.

## Problem
I want to get a random sample of an R data frame in which each variable, in both the training and testing sets, is relatively representative of the superset.

I have seen ways to create a stratified sample based on a single variable. But, I want to ensure representation on multiple variables and not just factors.

Caret has a very elegant way to split your data into training and testing sets, maxDissim, but it doesn't *ensure* maximum representation across all variables. In fact, running a Student's t-test or Wilcoxon rank sum test for each variable of a split reveals that we can be quite certain that some of these variables weren't split in a representative way (p < 0.1, even 0.01 in some cases).

## Attempt herein
Toward this end, I wrote a simple algorithm using the Wilcoxon test on each continuous variable. The assumption is that you probably have a fairly representative sample if all continuous variables in the sample (test set) seem to come from the same set as the continuous variables in the remaining set (train set). You take a random sample (train_test_split()) and validate it (validate_split()) by applying the Wilcoxon rank sum test to each continuous variable. If any single variable doesn't pass the test, resample and validate. Repeat until you get a sample that meets your minimum representativity (p > alpha) across all (continuous) variables.

In this case, because alpha represents the risk of incorrectly rejecting the null hypothesis (H0 = The samples did not come from significantly different populations, i.e. each side of the split is probably representative of the superset (and not some non-existent set).), and because we want to fail to reject the null hypothesis, we want a p-value greater than alpha rather than less than alpha, and we want the greatest alpha that we can muster.

### Drawbacks and suggested improvements
Again, this leaves out factors and integers entirely, unless you cast them as doubles, but that would violate the Wilcoxon assumption that the data is continuous. Given a data set in which a sufficient proportion of the features are doubles, perhaps this split method will at least improve the representativity of the factors and integers as well. Or, perhaps it will bias the split and overly weight numeric features during training.

Also, it can take a long, unpredictable time (possibly forever) to run and get even p > .5 on all variables.

Is there a better way, both/either from a mathematical/statistical perspective and/or an R/programming perspective? Also, is this somehow problematic for machine learning? I'd like to think that it would improve the generalizability of the trained/tuned model, reduce the chance of overfit, but does it somehow create leakage or something else problematic?

#### Tracking p-values
In the current implementation, I record the p-values of each variable on each run and find the mean of them at the end. This allows you to run a quick split with a low alpha and check the average p-values for each feature to help determine a reasonable alpha for the set and which features might be worth dropping from the validation.

As a commenter on [Stack Overflow](https://stackoverflow.com/questions/67995221/how-to-sample-r-dataframe-so-that-its-representative-across-multiple-variables) pointed out, this grows vectors to possibly an unmanageable size.

You could write in a parameter and logic to switch this task on an off. It's a simple fix, but not implemented here.

#### Limiting search
Because the search could theoretically run infinitely, it would be a good idea to write in a hard cap to the number of resamples tried or time spent searching. If you time out, you want to make sure you get the best sample rather than simply the last sample tried. You can store the index of the sample with the greatest minimum alpha, or median/mean or other preferred metric.

#### Dropping features
To save compute, you can drop features that will tend to the lowest alpha. To save compute and optimize features you care most about, you can omit features that you don't think will be very informative to your model anyway.

You'll want to be careful to avoid leakage in how you choose these features. For instance, don't run a regression on the full set to see which features have the least predictive importance. I considered using a feature's average p-value over n trials to determine mid-search whether to drop the feature from consideration in the following trials of the search, but I'm concerned that would create leakage as well.

#### Genetic algorithm
Rather than sampling and validating serially, "generations" of samples could be validated together, with relatively optimal members used to populate the next generation. Each sample could have a unique genetic identity, perhaps simply the index. The best samples could each "donate" a random subsample to be recombined with the donations of other fit samples and random samples from the superset. This new generation could then be validated, and new set of the most fit samples can be generated (with previous generations included in the competition).

This may reduce the number of samples/validations needed to converge on a solution, but it will come with some overhead as well.

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

Mann, Henry B.; Whitney, Donald R. (1947). "On a Test of Whether one of Two Random Variables is Stochastically Larger than the Other". Annals of Mathematical Statistics. 18 (1): 50–60. [doi:10.1214/aoms/1177730491](doi:10.1214/aoms/1177730491). MR 0022058. Zbl 0041.26103.

