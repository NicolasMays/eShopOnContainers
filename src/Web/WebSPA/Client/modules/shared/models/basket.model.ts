import { IBasketItem } from './basketItem.model';
import { ICoupon } from './coupon.model';
export interface IBasket {
    items: IBasketItem[];
    buyerId: string;
    coupon: ICoupon;
}
