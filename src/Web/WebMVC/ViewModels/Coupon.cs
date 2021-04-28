using System;
using System.Collections.Generic;
using System.Linq;

namespace Microsoft.eShopOnContainers.WebMVC.ViewModels
{
    public record Coupon
    {
        // Use property initializer syntax.
        // While this is often more useful for read only 
        // auto implemented properties, it can simplify logic
        // for read/write properties.
        public string CouponCode { get; init; }
        public string ExpirationDate { get; init; }
        public decimal Discount { get; init; }
       
    }
}
