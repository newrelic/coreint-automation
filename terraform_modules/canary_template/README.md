# Canary Template

Canary template is a skeleton that can be used to build modules for each specific integration canary.
It provides a way to access base framework resources, like private subnet ids, to reuse them in the new resource deployment.

**NOTE:** When deploying a new canary environment, set a new, unique [key](providers.tf#L12) to save the state of the canary.
