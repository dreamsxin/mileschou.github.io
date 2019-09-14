---
title: Container 差異
layout: collections
tags: [Laravel]
---

## PSR-11 實作

在 Laravel 5.5 開始，才實作 PSR-11。在之前的版本，則需要透過橋接器來達成。以下是一個簡單的範例：

```php
<?php

namespace LaravelBridge\Support;

use BadMethodCallException;
use Exception;
use Illuminate\Contracts\Container\Container;
use Psr\Container\ContainerInterface;

/**
 * @mixin \Illuminate\Contracts\Container\Container
 */
class ContainerBridge implements ContainerInterface
{    
    /**
     * @var Container
     */
    protected $container;

    /**
     * @param Container $container
     */
    public function __construct(Container $container)
    {
        $this->container = $container;
    }

    public function __call($method, $arguments)
    {
        if (method_exists($this->container, $method)) {
            return call_user_func_array([$this->container, $method], $arguments);
        }

        throw new BadMethodCallException("Undefined method '$method'");
    }

    /**
     *  {@inheritdoc}
     */
    public function get($id)
    {
        try {
            return $this->container->make($id);
        } catch (Exception $e) {
            if ($this->has($id)) {
                throw $e;
            }

            throw new EntryNotFoundException("Entry '$id' is not found");
        }
    }

    /**
     *  {@inheritdoc}
     */
    public function has($id)
    {
        return $this->container->bound($id);
    }
}
```

> 完整實作可以參考 [Laravel Bridge Support Library](https://github.com/laravel-bridge/support/blob/master/src/Support/ContainerBridge.php)。
