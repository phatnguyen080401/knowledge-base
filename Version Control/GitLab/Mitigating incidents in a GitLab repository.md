## Who can modify a protected branch
Below is a table which describes who can do with protected branch.

| **Action**               | **Who can do it**                   |
| ------------------------ | ----------------------------------- |
| Protect a branch         | At least the Maintainer role.       |
| Push to the branch       | Anyone with **Allowed** permission. |
| Force push to the branch | No one                              |
| Delete the branch        | No one                              |
## Branch rules
Go to **Settings** > **Repository** > **Branch rules**
- Add branch rules to define rules for which action they can do and the required approvals in a specific branch. 
- Merge requests: require a minimum number of approvals (at least 1) from designated reviewers or groups. This ensures that code changes are reviewed by multiple people before being merged.
## Push rules
Go to **Settings** > **Repository** > **Push rules**
- Check whether the commit author is a GitLab user: restrict commits to existing GitLab users.
- Prevent pushing secret files: reject any files likely to contain secrets.
- Commit author's email: all commit author's email must match regular expression.
## Merge requests
Go to **Settings** > **Merge requests**
- Create templates to standardize the merge request process.
- Templates can include checklists, descriptions of changes, and links to relevant issues.
## CI/CD
Go to **Settings** > **CI/CD**
- Uncheck **Public pipelines** box
- Use separate caches for protected branches.
- Set pipeline timeout.
- Use protected environments and tightly limit who can deploy and require approvals for deploying.
- Use secure files to store keystores, provisioning profiles and signing certificates in the Secure Files storage rather than the repository.
# Security
Go to **Secure** > **Security configuration**
- Enable SAST to analyze and detect vulnerabilities in source code.
- Enable Dependency scanning to analyze dependencies.
- Enable Container scanning.
- Enable Secret push protection to prevent pushing secret such as keys and API tokens to repositories.

[GitLab Configuration Best Practices](https://best.openssf.org/SCM-BestPractices/gitlab/)