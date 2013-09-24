# FFCRM Advanced Tasks Plugin

This plugin (ffcrm-tasks) enables Fat Free CRM to have group task views and tasks with comments/notes.  Here are some suggested practices for how to contribute to this project:

## A. Set Up
Make sure you have an account on github and you are part of the project team.

## B. Add your contributions
It is a git best practice to develop each new feature or bug fix in a new branch, and we strongly recommend you do the same with descriptive branch names.  It's trivial to create branches and switch between them.  Using them will make it simple for you to pause one task list item and begin another.  It also simplifies our process of tracking contributions to the main code base.  Submitting pull requests for the same branch over and again can sometimes lead to unexpected results, so the basic process should be:

##### 1. Checkout a new branch
    % cd ffcrm-tasks
    % git checkout -b my_descriptive_branch_name

You'll immediately be in the new branch.

##### 2. Implement your changes
Now, write some code!

##### 3. Stage and commit your changes
Git requires files be staged before committing.  You can add the files manually:

    % git add <file>

Or add the **-a** tag when you commit.

When you commit, just do the following:

    % git commit

This will commit your changes to your local copy of the repository.

##### 4. Push your changes

    % git push origin my_descriptive_branch_name

##### 5. Submit a pull request

Go to Github project website, switch to your branch, and click on the "Pull Request" button on the top.

You should then be able to add a descriptive comment about what is in this merge, and submit the pull request.  A project admin can then apply the merge to the primary code repository.

You can read more about pull requests here: http://help.github.com/pull-requests/

## E. Rinse and repeat

Have more to implement? Repeat the process from B-thru-E

#### More Reading

For more reading, check out the excellent Pro Git book online, especially the Public Small Project section in chapter 5.2: (http://progit.org/book/ch5-2.html).

*Taken from [GitHub Best Practices](https://github.com/skyscreamer/yoga/wiki/GitHub-Best-Practices)*
